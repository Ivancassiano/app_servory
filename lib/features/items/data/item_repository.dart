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
import 'item_mapper.dart';

/// Campos editáveis de um item — passados a `create`/`update` sem repetir a
/// lista gigante de argumentos.
class ItemFields {
  const ItemFields({
    required this.name,
    this.itemTypeId,
    this.contactPerson = '',
    this.phone = '',
    this.accessInstructions = '',
    this.brand = '',
    this.model = '',
    this.serialNumber = '',
    this.internalLocation = '',
    this.installedAt,
    this.cost,
    this.notes = '',
    this.address = ItemAddressInput.empty,
  });

  final String name;
  final String? itemTypeId;
  final String contactPerson;
  final String phone;
  final String accessInstructions;
  final String brand;
  final String model;
  final String serialNumber;
  final String internalLocation;
  final String? installedAt;
  final String? cost;
  final String notes;
  final ItemAddressInput address;
}

/// Ver [ClientRepository] para o racional das duas implementações.
abstract interface class ItemRepository {
  Stream<List<LocalItem>> watchList();
  Stream<LocalItem?> watchById(String id);
  Future<void> refresh();

  Future<String> create({
    required String clientId,
    String? parentItemId,
    required ItemFields fields,
  });

  Future<void> update({
    required String id,
    required int? baseVersion,
    required ItemFields fields,
  });

  /// Move o item para outro pai (ou raiz, se `parentItemId` for nulo).
  /// Online-only (PATCH /v1/items/{id}/parent).
  Future<void> reparent({
    required String id,
    required int? baseVersion,
    String? parentItemId,
  });
}

final itemRepositoryProvider = Provider<ItemRepository>((ref) {
  final orgId = ref.watch(organizationIdProvider);
  if (kIsWeb) {
    final repo = RemoteItemRepository(
      ref.watch(apiClientProvider).businessDio,
      orgId,
    );
    ref.onDispose(repo.dispose);
    return repo;
  }
  return LocalFirstItemRepository(ref);
});

// ---------------------------------------------------------------------------

class LocalFirstItemRepository extends LocalFirstRepositoryBase
    implements ItemRepository {
  LocalFirstItemRepository(super.ref);

  @override
  Stream<List<LocalItem>> watchList() {
    final q = db.select(db.localItems)
      ..where((t) => t.deleted.equals(false))
      ..orderBy([(t) => OrderingTerm(expression: t.name)]);
    return q.watch();
  }

  @override
  Stream<LocalItem?> watchById(String id) => (db.select(
    db.localItems,
  )..where((t) => t.id.equals(id))).watchSingleOrNull();

  @override
  Future<void> refresh() => runSync();

  @override
  Future<String> create({
    required String clientId,
    String? parentItemId,
    required ItemFields fields,
  }) async {
    final body = itemCreateBody(
      clientId: clientId,
      parentItemId: parentItemId,
      itemTypeId: fields.itemTypeId,
      name: fields.name,
      contactPerson: fields.contactPerson,
      phone: fields.phone,
      accessInstructions: fields.accessInstructions,
      brand: fields.brand,
      model: fields.model,
      serialNumber: fields.serialNumber,
      internalLocation: fields.internalLocation,
      installedAt: fields.installedAt,
      cost: fields.cost,
      notes: fields.notes,
      address: fields.address,
    );
    if (online) {
      try {
        final r = await restCall(() => dio.post('/v1/items', data: body));
        final it = itemFromApiJson(
          r.data as Map<String, dynamic>,
          organizationId: orgId,
        );
        await db.into(db.localItems).insertOnConflictUpdate(it);
        return it.id;
      } on ApiException catch (e) {
        if (!isOfflineError(e)) rethrow;
      }
    }
    final id = const Uuid().v4();
    await db.transaction(() async {
      await db
          .into(db.localItems)
          .insert(
            LocalItemsCompanion.insert(
              id: id,
              organizationId: orgId,
              clientId: clientId,
              parentItemId: Value(parentItemId),
              itemTypeId: Value(fields.itemTypeId),
              name: fields.name,
              postalCode: Value(fields.address.postalCode),
              street: Value(fields.address.street),
              number: Value(fields.address.number),
              complement: Value(fields.address.complement),
              district: Value(fields.address.district),
              city: Value(fields.address.city),
              state: Value(fields.address.state),
              contactPerson: Value(fields.contactPerson),
              phone: Value(fields.phone),
              accessInstructions: Value(fields.accessInstructions),
              brand: Value(fields.brand),
              model: Value(fields.model),
              serialNumber: Value(fields.serialNumber),
              internalLocation: Value(fields.internalLocation),
              installedAt: Value(fields.installedAt),
              cost: Value(fields.cost),
              notes: Value(fields.notes),
              localUpdatedAt: DateTime.now(),
              syncStatus: const Value('pending'),
              lastSyncedAt: const Value(null),
            ),
          );
      await enqueue(
        entityType: 'item',
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
    required ItemFields fields,
  }) async {
    final body = itemUpdateBody(
      itemTypeId: fields.itemTypeId,
      name: fields.name,
      contactPerson: fields.contactPerson,
      phone: fields.phone,
      accessInstructions: fields.accessInstructions,
      brand: fields.brand,
      model: fields.model,
      serialNumber: fields.serialNumber,
      internalLocation: fields.internalLocation,
      installedAt: fields.installedAt,
      cost: fields.cost,
      notes: fields.notes,
      address: fields.address,
    );
    if (online) {
      try {
        final r = await restCall(
          () => dio.patch(
            '/v1/items/$id',
            data: {...body, 'version': ?baseVersion},
          ),
        );
        await db
            .into(db.localItems)
            .insertOnConflictUpdate(
              itemFromApiJson(
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
      await (db.update(db.localItems)..where((t) => t.id.equals(id))).write(
        LocalItemsCompanion(
          itemTypeId: Value(fields.itemTypeId),
          name: Value(fields.name),
          postalCode: Value(fields.address.postalCode),
          street: Value(fields.address.street),
          number: Value(fields.address.number),
          complement: Value(fields.address.complement),
          district: Value(fields.address.district),
          city: Value(fields.address.city),
          state: Value(fields.address.state),
          contactPerson: Value(fields.contactPerson),
          phone: Value(fields.phone),
          accessInstructions: Value(fields.accessInstructions),
          brand: Value(fields.brand),
          model: Value(fields.model),
          serialNumber: Value(fields.serialNumber),
          internalLocation: Value(fields.internalLocation),
          installedAt: Value(fields.installedAt),
          cost: Value(fields.cost),
          notes: Value(fields.notes),
          localUpdatedAt: Value(DateTime.now()),
          syncStatus: const Value('pending'),
        ),
      );
      await enqueue(
        entityType: 'item',
        entityId: id,
        operationType: 'update',
        payload: body,
        baseVersion: baseVersion,
      );
    });
    unawaited(trySyncNow());
  }

  @override
  Future<void> reparent({
    required String id,
    required int? baseVersion,
    String? parentItemId,
  }) async {
    final r = await restCall(
      () => dio.patch(
        '/v1/items/$id/parent',
        data: {'parent_item_id': parentItemId, 'version': ?baseVersion},
      ),
    );
    await db
        .into(db.localItems)
        .insertOnConflictUpdate(
          itemFromApiJson(
            r.data as Map<String, dynamic>,
            organizationId: orgId,
          ),
        );
  }
}

// ---------------------------------------------------------------------------

class RemoteItemRepository implements ItemRepository, PagedListRepository {
  RemoteItemRepository(Dio dio, String orgId)
    : _dio = dio,
      _collection = RemoteCollection<LocalItem>(
        dio: dio,
        listPath: '/v1/items',
        listKey: 'items',
        fromJson: (j) => itemFromApiJson(j, organizationId: orgId),
        idOf: (i) => i.id,
        pageSize: 50,
      );

  final Dio _dio;
  final RemoteCollection<LocalItem> _collection;

  @override
  PagedSource? get listPaging => _collection;

  void dispose() => _collection.dispose();

  @override
  Stream<List<LocalItem>> watchList() => _collection.watchList();

  @override
  Stream<LocalItem?> watchById(String id) => _collection.watchById(id);

  @override
  Future<void> refresh() => _collection.refresh();

  @override
  Future<String> create({
    required String clientId,
    String? parentItemId,
    required ItemFields fields,
  }) async {
    final it = await _collection.create(
      itemCreateBody(
        clientId: clientId,
        parentItemId: parentItemId,
        itemTypeId: fields.itemTypeId,
        name: fields.name,
        contactPerson: fields.contactPerson,
        phone: fields.phone,
        accessInstructions: fields.accessInstructions,
        brand: fields.brand,
        model: fields.model,
        serialNumber: fields.serialNumber,
        internalLocation: fields.internalLocation,
        installedAt: fields.installedAt,
        cost: fields.cost,
        notes: fields.notes,
        address: fields.address,
      ),
    );
    return it.id;
  }

  @override
  Future<void> update({
    required String id,
    required int? baseVersion,
    required ItemFields fields,
  }) async {
    await _collection.update(id, {
      ...itemUpdateBody(
        itemTypeId: fields.itemTypeId,
        name: fields.name,
        contactPerson: fields.contactPerson,
        phone: fields.phone,
        accessInstructions: fields.accessInstructions,
        brand: fields.brand,
        model: fields.model,
        serialNumber: fields.serialNumber,
        internalLocation: fields.internalLocation,
        installedAt: fields.installedAt,
        cost: fields.cost,
        notes: fields.notes,
        address: fields.address,
      ),
      'version': ?baseVersion,
    });
  }

  @override
  Future<void> reparent({
    required String id,
    required int? baseVersion,
    String? parentItemId,
  }) async {
    await restCall(
      () => _dio.patch(
        '/v1/items/$id/parent',
        data: {'parent_item_id': parentItemId, 'version': ?baseVersion},
      ),
    );
    await _collection.refresh();
  }
}
