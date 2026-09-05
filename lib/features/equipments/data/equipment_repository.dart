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
import 'equipment_mapper.dart';

/// Ver [ClientRepository]. Criar equipamento: Fatia 2 (exige seletor de
/// local + tipo de equipamento).
abstract interface class EquipmentRepository {
  Stream<List<LocalEquipment>> watchList();
  Stream<LocalEquipment?> watchById(String id);
  Future<void> refresh();
  Future<void> update({
    required String id,
    required int? baseVersion,
    required String name,
    required String brand,
    required String model,
    required String notes,
  });
}

final equipmentRepositoryProvider = Provider<EquipmentRepository>((ref) {
  final orgId = ref.watch(organizationIdProvider);
  if (kIsWeb) {
    final repo = RemoteEquipmentRepository(
      ref.watch(apiClientProvider).businessDio,
      orgId,
    );
    ref.onDispose(repo.dispose);
    return repo;
  }
  return LocalFirstEquipmentRepository(ref);
});

// ---------------------------------------------------------------------------

class LocalFirstEquipmentRepository extends LocalFirstRepositoryBase
    implements EquipmentRepository {
  LocalFirstEquipmentRepository(super.ref);

  @override
  Stream<List<LocalEquipment>> watchList() {
    final q = db.select(db.localEquipments)
      ..where((t) => t.deleted.equals(false))
      ..orderBy([(t) => OrderingTerm(expression: t.name)]);
    return q.watch();
  }

  @override
  Stream<LocalEquipment?> watchById(String id) =>
      (db.select(db.localEquipments)..where((t) => t.id.equals(id)))
          .watchSingleOrNull();

  @override
  Future<void> refresh() => runSync();

  @override
  Future<void> update({
    required String id,
    required int? baseVersion,
    required String name,
    required String brand,
    required String model,
    required String notes,
  }) async {
    final body = equipmentUpdateBody(
      name: name,
      brand: brand,
      model: model,
      notes: notes,
    );
    if (online) {
      try {
        final r = await restCall(
          () => dio.patch(
            '/v1/equipments/$id',
            data: {...body, 'version': ?baseVersion},
          ),
        );
        await db.into(db.localEquipments).insertOnConflictUpdate(
              equipmentFromApiJson(
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
      await (db.update(db.localEquipments)..where((t) => t.id.equals(id))).write(
        LocalEquipmentsCompanion(
          name: Value(name),
          brand: Value(brand),
          model: Value(model),
          notes: Value(notes),
          localUpdatedAt: Value(DateTime.now()),
          syncStatus: const Value('pending'),
        ),
      );
      await enqueue(
        entityType: 'equipment',
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

class RemoteEquipmentRepository implements EquipmentRepository {
  RemoteEquipmentRepository(Dio dio, String orgId)
    : _collection = RemoteCollection<LocalEquipment>(
        dio: dio,
        listPath: '/v1/equipments',
        listKey: 'equipments',
        fromJson: (j) => equipmentFromApiJson(j, organizationId: orgId),
        idOf: (e) => e.id,
      );

  final RemoteCollection<LocalEquipment> _collection;

  void dispose() => _collection.dispose();

  @override
  Stream<List<LocalEquipment>> watchList() => _collection.watchList();

  @override
  Stream<LocalEquipment?> watchById(String id) => _collection.watchById(id);

  @override
  Future<void> refresh() => _collection.refresh();

  @override
  Future<void> update({
    required String id,
    required int? baseVersion,
    required String name,
    required String brand,
    required String model,
    required String notes,
  }) async {
    await _collection.update(id, {
      ...equipmentUpdateBody(name: name, brand: brand, model: model, notes: notes),
      'version': ?baseVersion,
    });
  }
}
