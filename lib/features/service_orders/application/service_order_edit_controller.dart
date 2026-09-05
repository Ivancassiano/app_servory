import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/db/app_database.dart';
import '../../auth/application/session_controller.dart';
import '../../sync/application/sync_provider.dart';

/// Cabeçalho da ordem, local-primeiro (GUIA-FLUTTER.md §8.1), mesmo molde de
/// `ClientEditController`. `start`/`complete`/`reopen` são ações nomeadas do
/// protocolo de sync (ADR-0018) — gravam o novo estado local de forma
/// otimista e mandam `operation_type` = a própria ação, com `payload`
/// vazio (o servidor decide id, versão manda em `base_version`). Se o
/// servidor rejeitar por transição inválida (visão desatualizada), a linha
/// fica `conflict` — mesma orientação do guia: puxar pra baixo mostra o
/// estado real, o app nunca tenta adivinhar/reverter sozinho.
class ServiceOrderEditController {
  ServiceOrderEditController(this._ref);
  final Ref _ref;

  AppDatabase get _db => _ref.read(appDatabaseProvider);

  String get _organizationId {
    final session = _ref.read(sessionControllerProvider);
    if (session is! SessionAuthenticated) {
      throw StateError(
        'ServiceOrderEditController usado sem sessão autenticada',
      );
    }
    return session.organizationId;
  }

  /// `clientId` só existe aqui — imutável depois de criada (o servidor não
  /// aceita `client_id` no `update`, GUIA-FLUTTER.md §8.4).
  Future<String> create({
    required String clientId,
    String? locationId,
    String? equipmentId,
    required bool open,
    required String reason,
  }) async {
    final organizationId = _organizationId;
    final now = DateTime.now();
    final id = const Uuid().v4();

    await _db.transaction(() async {
      await _db
          .into(_db.localServiceOrders)
          .insert(
            LocalServiceOrdersCompanion.insert(
              id: id,
              organizationId: organizationId,
              clientId: clientId,
              locationId: Value(locationId),
              equipmentId: Value(equipmentId),
              status: Value(open ? 'open' : 'draft'),
              reason: Value(reason),
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
              entityType: 'service_order',
              entityId: id,
              operationType: 'create',
              payload: jsonEncode({
                'client_id': clientId,
                'location_id': ?locationId,
                'equipment_id': ?equipmentId,
                'open': open,
                'reason': reason,
              }),
              occurredAt: now,
            ),
          );
    });

    unawaited(_trySyncNow());
    return id;
  }

  Future<void> update({
    required String serviceOrderId,
    String? locationId,
    String? equipmentId,
    required String reason,
    required String diagnosis,
    required String workPerformed,
    required String finalCondition,
    required String notes,
  }) async {
    final organizationId = _organizationId;
    final now = DateTime.now();

    await _db.transaction(() async {
      final current = await (_db.select(
        _db.localServiceOrders,
      )..where((t) => t.id.equals(serviceOrderId))).getSingle();

      await (_db.update(
        _db.localServiceOrders,
      )..where((t) => t.id.equals(serviceOrderId))).write(
        LocalServiceOrdersCompanion(
          locationId: locationId != null
              ? Value(locationId)
              : const Value.absent(),
          equipmentId: equipmentId != null
              ? Value(equipmentId)
              : const Value.absent(),
          reason: Value(reason),
          diagnosis: Value(diagnosis),
          workPerformed: Value(workPerformed),
          finalCondition: Value(finalCondition),
          notes: Value(notes),
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
              entityType: 'service_order',
              entityId: serviceOrderId,
              operationType: 'update',
              payload: jsonEncode({
                'location_id': ?locationId,
                'equipment_id': ?equipmentId,
                'reason': reason,
                'diagnosis': diagnosis,
                'work_performed': workPerformed,
                'final_condition': finalCondition,
                'notes': notes,
              }),
              baseVersion: Value(current.version),
              occurredAt: now,
            ),
          );
    });

    unawaited(_trySyncNow());
  }

  Future<void> start(String serviceOrderId) => _transition(
    serviceOrderId,
    action: 'start',
    newStatus: 'in_progress',
    setStartedAtNow: true,
  );

  Future<void> complete(String serviceOrderId) => _transition(
    serviceOrderId,
    action: 'complete',
    newStatus: 'completed',
    setCompletedAtNow: true,
  );

  Future<void> reopen(String serviceOrderId) => _transition(
    serviceOrderId,
    action: 'reopen',
    newStatus: 'in_progress',
    clearCompletedAt: true,
  );

  /// Espelha `transition` do backend
  /// (`internal/serviceorders/serviceorders.go`) só pra não repetir 3x o
  /// mesmo bloco de outbox — `start`/`complete`/`reopen` só diferem no
  /// status resultante e em qual timestamp tocam.
  Future<void> _transition(
    String serviceOrderId, {
    required String action,
    required String newStatus,
    bool setStartedAtNow = false,
    bool setCompletedAtNow = false,
    bool clearCompletedAt = false,
  }) async {
    final organizationId = _organizationId;
    final now = DateTime.now();

    await _db.transaction(() async {
      final current = await (_db.select(
        _db.localServiceOrders,
      )..where((t) => t.id.equals(serviceOrderId))).getSingle();

      await (_db.update(
        _db.localServiceOrders,
      )..where((t) => t.id.equals(serviceOrderId))).write(
        LocalServiceOrdersCompanion(
          status: Value(newStatus),
          startedAt: setStartedAtNow ? Value(now) : const Value.absent(),
          completedAt: setCompletedAtNow
              ? Value(now)
              : (clearCompletedAt ? const Value(null) : const Value.absent()),
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
              entityType: 'service_order',
              entityId: serviceOrderId,
              operationType: action,
              payload: jsonEncode(const {}),
              baseVersion: Value(current.version),
              occurredAt: now,
            ),
          );
    });

    unawaited(_trySyncNow());
  }

  Future<void> _trySyncNow() async {
    try {
      await _ref.read(syncRunnerProvider.notifier).runSync();
    } catch (_) {
      // silencioso de propósito: outbox já garante retry depois.
    }
  }
}

final serviceOrderEditControllerProvider =
    Provider<ServiceOrderEditController>(
      (ref) => ServiceOrderEditController(ref),
    );
