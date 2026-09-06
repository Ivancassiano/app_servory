import 'dart:async';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../sync/data/local_first_repository.dart';
import '../../../core/data/remote_collection.dart';
import '../../../core/db/app_database.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/rest.dart';
import '../../../core/providers.dart';
import '../../auth/application/session_controller.dart';
import 'client_mapper.dart';

/// Contrato de acesso a clientes. Duas implementações:
/// - [LocalFirstClientRepository] (apps): online → REST direto + aquece o
///   cache drift; offline/erro de rede → grava local + fila de sync.
/// - [RemoteClientRepository] (web): REST puro, cache em memória.
abstract interface class ClientRepository {
  Stream<List<LocalClient>> watchList();
  Stream<LocalClient?> watchById(String id);

  /// Recarrega do servidor (pull-to-refresh). No app dispara `runSync`.
  Future<void> refresh();

  /// Retorna o `id` do cliente criado (do servidor quando online, gerado
  /// localmente quando offline).
  Future<String> create({
    required String kind,
    required String name,
    required String phone,
  });

  Future<void> update({
    required String id,
    required int? baseVersion,
    required String name,
    required String phone,
  });
}

final clientRepositoryProvider = Provider<ClientRepository>((ref) {
  // Rebuild ao trocar de sessão/organização (o cache/stream é por org).
  final orgId = ref.watch(organizationIdProvider);
  if (kIsWeb) {
    final repo = RemoteClientRepository(
      ref.watch(apiClientProvider).businessDio,
      orgId,
    );
    ref.onDispose(repo.dispose);
    return repo;
  }
  return LocalFirstClientRepository(ref);
});

// ---------------------------------------------------------------------------

class LocalFirstClientRepository extends LocalFirstRepositoryBase
    implements ClientRepository {
  LocalFirstClientRepository(super.ref);

  @override
  Stream<List<LocalClient>> watchList() {
    final q = db.select(db.localClients)
      ..where((t) => t.deleted.equals(false))
      ..orderBy([(t) => OrderingTerm(expression: t.name)]);
    return q.watch();
  }

  @override
  Stream<LocalClient?> watchById(String id) =>
      (db.select(db.localClients)..where((t) => t.id.equals(id)))
          .watchSingleOrNull();

  @override
  Future<void> refresh() => runSync();

  @override
  Future<String> create({
    required String kind,
    required String name,
    required String phone,
  }) async {
    final body = clientCreateBody(kind: kind, name: name, phone: phone);
    if (online) {
      try {
        final r = await restCall(() => dio.post('/v1/clients', data: body));
        final client = clientFromApiJson(
          r.data as Map<String, dynamic>,
          organizationId: orgId,
        );
        await db.into(db.localClients).insertOnConflictUpdate(client);
        return client.id;
      } on ApiException catch (e) {
        if (!isOfflineError(e)) rethrow;
      }
    }
    final id = const Uuid().v4();
    await db.transaction(() async {
      await db.into(db.localClients).insert(
            LocalClientsCompanion.insert(
              id: id,
              organizationId: orgId,
              kind: kind,
              name: name,
              phone: Value(phone),
              localUpdatedAt: DateTime.now(),
              syncStatus: const Value('pending'),
              lastSyncedAt: const Value(null),
            ),
          );
      await enqueue(
        entityType: 'client',
        entityId: id,
        operationType: 'create',
        payload: body,
      );
    });
    unawaited(trySyncNow());
    return id;
  }

  @override
  Future<void> update({
    required String id,
    required int? baseVersion,
    required String name,
    required String phone,
  }) async {
    final body = clientUpdateBody(name: name, phone: phone);
    if (online) {
      try {
        final r = await restCall(
          () => dio.patch(
            '/v1/clients/$id',
            data: {...body, 'version': ?baseVersion},
          ),
        );
        await db.into(db.localClients).insertOnConflictUpdate(
              clientFromApiJson(
                r.data as Map<String, dynamic>,
                organizationId: orgId,
              ),
            );
        return;
      } on ApiException catch (e) {
        if (!isOfflineError(e)) rethrow;
      }
    }
    await db.transaction(() async {
      await (db.update(db.localClients)..where((t) => t.id.equals(id))).write(
        LocalClientsCompanion(
          name: Value(name),
          phone: Value(phone),
          localUpdatedAt: Value(DateTime.now()),
          syncStatus: const Value('pending'),
        ),
      );
      await enqueue(
        entityType: 'client',
        entityId: id,
        operationType: 'update',
        payload: body,
        baseVersion: baseVersion,
      );
    });
    unawaited(trySyncNow());
  }
}

// ---------------------------------------------------------------------------

class RemoteClientRepository implements ClientRepository {
  RemoteClientRepository(Dio dio, String orgId)
    : _collection = RemoteCollection<LocalClient>(
        dio: dio,
        listPath: '/v1/clients',
        listKey: 'clients',
        fromJson: (j) => clientFromApiJson(j, organizationId: orgId),
        idOf: (c) => c.id,
      );

  final RemoteCollection<LocalClient> _collection;

  void dispose() => _collection.dispose();

  @override
  Stream<List<LocalClient>> watchList() => _collection.watchList();

  @override
  Stream<LocalClient?> watchById(String id) => _collection.watchById(id);

  @override
  Future<void> refresh() => _collection.refresh();

  @override
  Future<String> create({
    required String kind,
    required String name,
    required String phone,
  }) async {
    final client = await _collection.create(
      clientCreateBody(kind: kind, name: name, phone: phone),
    );
    return client.id;
  }

  @override
  Future<void> update({
    required String id,
    required int? baseVersion,
    required String name,
    required String phone,
  }) async {
    await _collection.update(id, {
      ...clientUpdateBody(name: name, phone: phone),
      'version': ?baseVersion,
    });
  }
}
