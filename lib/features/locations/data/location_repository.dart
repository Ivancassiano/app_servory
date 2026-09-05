import 'dart:async';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../sync/data/local_first_repository.dart';
import '../../../core/data/remote_collection.dart';
import '../../../core/db/app_database.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/rest.dart';
import '../../../core/providers.dart';
import '../../auth/application/session_controller.dart';
import 'location_mapper.dart';

/// Ver [ClientRepository] para o racional das duas implementações.
/// Criar local fica pra Fatia 2 (exige seletor de cliente/pai).
abstract interface class LocationRepository {
  Stream<List<LocalLocation>> watchList();
  Stream<LocalLocation?> watchById(String id);
  Future<void> refresh();
  Future<void> update({
    required String id,
    required int? baseVersion,
    required String name,
    required String contactPerson,
    required String phone,
    required String notes,
  });
}

final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  final orgId = ref.watch(organizationIdProvider);
  if (kIsWeb) {
    final repo = RemoteLocationRepository(
      ref.watch(apiClientProvider).businessDio,
      orgId,
    );
    ref.onDispose(repo.dispose);
    return repo;
  }
  return LocalFirstLocationRepository(ref);
});

// ---------------------------------------------------------------------------

class LocalFirstLocationRepository extends LocalFirstRepositoryBase
    implements LocationRepository {
  LocalFirstLocationRepository(super.ref);

  @override
  Stream<List<LocalLocation>> watchList() {
    final q = db.select(db.localLocations)
      ..where((t) => t.deleted.equals(false))
      ..orderBy([(t) => OrderingTerm(expression: t.name)]);
    return q.watch();
  }

  @override
  Stream<LocalLocation?> watchById(String id) =>
      (db.select(db.localLocations)..where((t) => t.id.equals(id)))
          .watchSingleOrNull();

  @override
  Future<void> refresh() => runSync();

  @override
  Future<void> update({
    required String id,
    required int? baseVersion,
    required String name,
    required String contactPerson,
    required String phone,
    required String notes,
  }) async {
    final body = locationUpdateBody(
      name: name,
      contactPerson: contactPerson,
      phone: phone,
      notes: notes,
    );
    if (online) {
      try {
        final r = await restCall(
          () => dio.patch(
            '/v1/locations/$id',
            data: {...body, 'version': ?baseVersion},
          ),
        );
        await db.into(db.localLocations).insertOnConflictUpdate(
              locationFromApiJson(
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
      await (db.update(db.localLocations)..where((t) => t.id.equals(id))).write(
        LocalLocationsCompanion(
          name: Value(name),
          contactPerson: Value(contactPerson),
          phone: Value(phone),
          notes: Value(notes),
          localUpdatedAt: Value(DateTime.now()),
          syncStatus: const Value('pending'),
        ),
      );
      await enqueue(
        entityType: 'location',
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

class RemoteLocationRepository implements LocationRepository {
  RemoteLocationRepository(Dio dio, String orgId)
    : _collection = RemoteCollection<LocalLocation>(
        dio: dio,
        listPath: '/v1/locations',
        listKey: 'locations',
        fromJson: (j) => locationFromApiJson(j, organizationId: orgId),
        idOf: (l) => l.id,
      );

  final RemoteCollection<LocalLocation> _collection;

  void dispose() => _collection.dispose();

  @override
  Stream<List<LocalLocation>> watchList() => _collection.watchList();

  @override
  Stream<LocalLocation?> watchById(String id) => _collection.watchById(id);

  @override
  Future<void> refresh() => _collection.refresh();

  @override
  Future<void> update({
    required String id,
    required int? baseVersion,
    required String name,
    required String contactPerson,
    required String phone,
    required String notes,
  }) async {
    await _collection.update(id, {
      ...locationUpdateBody(
        name: name,
        contactPerson: contactPerson,
        phone: phone,
        notes: notes,
      ),
      'version': ?baseVersion,
    });
  }
}
