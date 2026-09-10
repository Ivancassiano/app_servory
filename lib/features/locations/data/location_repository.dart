import 'dart:async';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/data/paged_source.dart';
import '../../../core/data/remote_collection.dart';
import '../../../core/db/app_database.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/rest.dart';
import '../../../core/providers.dart';
import '../../auth/application/session_controller.dart';
import '../../sync/data/local_first_repository.dart';
import 'location_mapper.dart';

/// Campos editáveis de um local.
class LocationFields {
  const LocationFields({
    required this.name,
    this.notes = '',
    this.address = LocationAddressInput.empty,
    this.isActive = true,
  });

  final String name;
  final String notes;
  final LocationAddressInput address;
  final bool isActive;

  /// Campos de um local existente (para editar só uma coisa e reenviar o resto).
  factory LocationFields.of(LocalLocation l) => LocationFields(
    name: l.name,
    notes: l.notes,
    address: LocationAddressInput.of(l),
    isActive: l.isActive,
  );
}

/// Ver [ItemRepository] para o racional das duas implementações.
abstract interface class LocationRepository {
  Stream<List<LocalLocation>> watchList();
  Stream<LocalLocation?> watchById(String id);
  Future<void> refresh();

  Future<String> create({
    required String clientId,
    required LocationFields fields,
  });

  Future<void> update({
    required String id,
    required int? baseVersion,
    required LocationFields fields,
  });

  /// Soft-delete (tombstone via sync).
  Future<void> delete({required String id, required int? baseVersion});
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
  Stream<LocalLocation?> watchById(String id) => (db.select(
    db.localLocations,
  )..where((t) => t.id.equals(id))).watchSingleOrNull();

  @override
  Future<void> refresh() => runSync();

  @override
  Future<String> create({
    required String clientId,
    required LocationFields fields,
  }) async {
    final body = locationCreateBody(
      clientId: clientId,
      name: fields.name,
      notes: fields.notes,
      address: fields.address,
      isActive: fields.isActive,
    );
    if (online) {
      try {
        final r = await restCall(() => dio.post('/v1/locations', data: body));
        final l = locationFromApiJson(
          r.data as Map<String, dynamic>,
          organizationId: orgId,
        );
        await db.into(db.localLocations).insertOnConflictUpdate(l);
        return l.id;
      } on ApiException catch (e) {
        if (!isOfflineError(e)) rethrow;
      }
    }
    final id = const Uuid().v4();
    await db.transaction(() async {
      await db
          .into(db.localLocations)
          .insert(
            LocalLocationsCompanion.insert(
              id: id,
              organizationId: orgId,
              clientId: clientId,
              name: Value(fields.name),
              postalCode: Value(fields.address.postalCode),
              street: Value(fields.address.street),
              number: Value(fields.address.number),
              complement: Value(fields.address.complement),
              district: Value(fields.address.district),
              city: Value(fields.address.city),
              state: Value(fields.address.state),
              notes: Value(fields.notes),
              isActive: Value(fields.isActive),
              localUpdatedAt: DateTime.now(),
              syncStatus: const Value('pending'),
              lastSyncedAt: const Value(null),
            ),
          );
      await enqueue(
        entityType: 'location',
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
    required LocationFields fields,
  }) async {
    final body = locationUpdateBody(
      name: fields.name,
      notes: fields.notes,
      address: fields.address,
      isActive: fields.isActive,
    );
    if (online) {
      try {
        final r = await restCall(
          () => dio.patch(
            '/v1/locations/$id',
            data: {...body, 'version': ?baseVersion},
          ),
        );
        await db
            .into(db.localLocations)
            .insertOnConflictUpdate(
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
          name: Value(fields.name),
          postalCode: Value(fields.address.postalCode),
          street: Value(fields.address.street),
          number: Value(fields.address.number),
          complement: Value(fields.address.complement),
          district: Value(fields.address.district),
          city: Value(fields.address.city),
          state: Value(fields.address.state),
          notes: Value(fields.notes),
          isActive: Value(fields.isActive),
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

  @override
  Future<void> delete({required String id, required int? baseVersion}) async {
    if (online) {
      try {
        await restCall(() => dio.delete('/v1/locations/$id'));
        await (db.update(db.localLocations)..where((t) => t.id.equals(id)))
            .write(const LocalLocationsCompanion(deleted: Value(true)));
        return;
      } on ApiException catch (e) {
        if (!isOfflineError(e)) rethrow;
      }
    }
    await db.transaction(() async {
      await (db.update(db.localLocations)..where((t) => t.id.equals(id))).write(
        LocalLocationsCompanion(
          deleted: const Value(true),
          localUpdatedAt: Value(DateTime.now()),
          syncStatus: const Value('pending'),
        ),
      );
      await enqueue(
        entityType: 'location',
        entityId: id,
        operationType: 'delete',
        payload: const {},
        baseVersion: baseVersion,
      );
    });
    unawaited(trySyncNow());
  }
}

// ---------------------------------------------------------------------------

class RemoteLocationRepository
    implements LocationRepository, PagedListRepository {
  RemoteLocationRepository(Dio dio, String orgId)
    : _collection = RemoteCollection<LocalLocation>(
        dio: dio,
        listPath: '/v1/locations',
        listKey: 'locations',
        fromJson: (j) => locationFromApiJson(j, organizationId: orgId),
        idOf: (l) => l.id,
        pageSize: 50,
      );

  final RemoteCollection<LocalLocation> _collection;

  @override
  PagedSource? get listPaging => _collection;

  void dispose() => _collection.dispose();

  @override
  Stream<List<LocalLocation>> watchList() => _collection.watchList();

  @override
  Stream<LocalLocation?> watchById(String id) => _collection.watchById(id);

  @override
  Future<void> refresh() => _collection.refresh();

  @override
  Future<String> create({
    required String clientId,
    required LocationFields fields,
  }) async {
    final l = await _collection.create(
      locationCreateBody(
        clientId: clientId,
        name: fields.name,
        notes: fields.notes,
        address: fields.address,
        isActive: fields.isActive,
      ),
    );
    return l.id;
  }

  @override
  Future<void> update({
    required String id,
    required int? baseVersion,
    required LocationFields fields,
  }) async {
    await _collection.update(id, {
      ...locationUpdateBody(
        name: fields.name,
        notes: fields.notes,
        address: fields.address,
        isActive: fields.isActive,
      ),
      'version': ?baseVersion,
    });
  }

  @override
  Future<void> delete({required String id, required int? baseVersion}) =>
      _collection.remove(id);
}
