import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/db/app_database.dart';
import '../../auth/application/session_controller.dart';
import '../../sync/application/sync_provider.dart';

/// Escreve local-primeiro (grava na tabela + na outbox na mesma
/// transação, GUIA-FLUTTER.md §8.1) e só depois tenta sincronizar — nunca
/// bloqueia a UI esperando rede; se estiver offline, a linha fica
/// `pending` até a próxima sincronização.
class ClientEditController {
  ClientEditController(this._ref);
  final Ref _ref;

  AppDatabase get _db => _ref.read(appDatabaseProvider);

  String get _organizationId {
    final session = _ref.read(sessionControllerProvider);
    if (session is! SessionAuthenticated) {
      throw StateError('ClientEditController usado sem sessão autenticada');
    }
    return session.organizationId;
  }

  /// `kind` é imutável após a criação (spec §7.3) — só existe aqui.
  Future<String> create({
    required String kind,
    required String name,
    required String phone,
  }) async {
    final organizationId = _organizationId;
    final now = DateTime.now();
    final id = const Uuid().v4();

    await _db.transaction(() async {
      await _db
          .into(_db.localClients)
          .insert(
            LocalClientsCompanion.insert(
              id: id,
              organizationId: organizationId,
              kind: kind,
              name: name,
              phone: Value(phone),
              localUpdatedAt: now,
              syncStatus: const Value('pending'),
              lastSyncedAt: const Value(null),
            ),
          );
      await _db
          .into(_db.syncOutbox)
          .insert(
            SyncOutboxCompanion.insert(
              operationId: const Uuid().v4(),
              organizationId: organizationId,
              entityType: 'client',
              entityId: id,
              operationType: 'create',
              payload: jsonEncode({'kind': kind, 'name': name, 'phone': phone}),
              occurredAt: now,
            ),
          );
    });

    unawaited(_trySyncNow());
    return id;
  }

  Future<void> update({
    required String clientId,
    required String name,
    required String phone,
  }) async {
    final organizationId = _organizationId;
    final now = DateTime.now();

    await _db.transaction(() async {
      final current = await (_db.select(
        _db.localClients,
      )..where((t) => t.id.equals(clientId))).getSingle();

      await (_db.update(
        _db.localClients,
      )..where((t) => t.id.equals(clientId))).write(
        LocalClientsCompanion(
          name: Value(name),
          phone: Value(phone),
          localUpdatedAt: Value(now),
          syncStatus: const Value('pending'),
        ),
      );
      await _db
          .into(_db.syncOutbox)
          .insert(
            SyncOutboxCompanion.insert(
              operationId: const Uuid().v4(),
              organizationId: organizationId,
              entityType: 'client',
              entityId: clientId,
              operationType: 'update',
              payload: jsonEncode({'name': name, 'phone': phone}),
              baseVersion: Value(current.version),
              occurredAt: now,
            ),
          );
    });

    unawaited(_trySyncNow());
  }

  /// Melhor esforço: se estiver offline ou a chamada falhar, a linha já
  /// está gravada localmente e será enviada na próxima sincronização —
  /// nada aqui pode apagar ou reverter o que já foi salvo (spec §25).
  Future<void> _trySyncNow() async {
    try {
      await _ref.read(syncRunnerProvider.notifier).runSync();
    } catch (_) {
      // silencioso de propósito: outbox já garante retry depois.
    }
  }
}

final clientEditControllerProvider = Provider<ClientEditController>(
  (ref) => ClientEditController(ref),
);
