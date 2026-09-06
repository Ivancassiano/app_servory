import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/connectivity/connectivity_provider.dart';
import '../../../core/db/app_database.dart';
import '../../../core/providers.dart';
import '../../auth/application/session_controller.dart';
import '../application/sync_provider.dart';

/// Base dos repositórios "online-first" dos apps: online → REST direto e
/// aquece o cache drift; offline / erro de rede → grava local + fila de
/// sync (comportamento original). O web usa implementações REST puras
/// separadas.
abstract class LocalFirstRepositoryBase {
  LocalFirstRepositoryBase(this.ref);
  final Ref ref;

  AppDatabase get db => ref.read(appDatabaseProvider);
  Dio get dio => ref.read(apiClientProvider).businessDio;
  String get orgId => ref.read(organizationIdProvider);

  /// `null` enquanto o stream de conectividade não emitiu → assume online
  /// (não vale mandar pra fila sem ter certeza que está offline).
  bool get online => ref.read(isOnlineProvider).value ?? true;

  Future<void> runSync() =>
      ref.read(syncRunnerProvider.notifier).runSync();

  /// Melhor esforço: a linha já está na outbox, então uma falha aqui só
  /// adia o envio.
  Future<void> trySyncNow() async {
    try {
      await runSync();
    } catch (_) {}
  }

  /// Insere uma operação na outbox local (mesma transação que a escrita da
  /// entidade, quando dentro de `db.transaction`).
  Future<void> enqueue({
    required String entityType,
    required String entityId,
    required String operationType,
    required Map<String, dynamic> payload,
    int? baseVersion,
  }) {
    return db.into(db.syncOutbox).insert(
          SyncOutboxCompanion.insert(
            operationId: const Uuid().v4(),
            organizationId: orgId,
            entityType: entityType,
            entityId: entityId,
            operationType: operationType,
            payload: jsonEncode(payload),
            baseVersion: Value(baseVersion),
            occurredAt: DateTime.now(),
          ),
        );
  }
}
