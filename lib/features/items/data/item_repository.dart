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

/// Campos editáveis de um item. A ficha técnica (marca/modelo/série/custo)
/// saiu do formulário — o backend preserva os valores existentes (`pick`).
class ItemFields {
  const ItemFields({
    required this.name,
    this.itemTypeId,
    this.locationId,
    this.notes = '',
    this.isActive = true,
  });

  final String name;
  final String? itemTypeId;
  final String? locationId;
  final String notes;
  final bool isActive;

  /// Campos de um item existente (edita um e reenvia o resto).
  factory ItemFields.of(LocalItem i) => ItemFields(
    name: i.name,
    itemTypeId: i.itemTypeId,
    locationId: i.locationId,
    notes: i.notes,
    isActive: i.isActive,
  );
}

/// Ver [ClientRepository] para o racional das duas implementações.
abstract interface class ItemRepository {
  Stream<List<LocalItem>> watchList();
  Stream<LocalItem?> watchById(String id);
  Future<void> refresh();

  Future<String> create({
    required String clientId,
    required ItemFields fields,
  });

  Future<void> update({
    required String id,
    required int? baseVersion,
    required ItemFields fields,
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
    required ItemFields fields,
  }) async {
    final body = itemCreateBody(
      clientId: clientId,
      itemTypeId: fields.itemTypeId,
      locationId: fields.locationId,
      name: fields.name,
      notes: fields.notes,
      isActive: fields.isActive,
    );
    if (online) {
      try {
        final r = await restCall(() => dio.post('/v1/items', data: body));
        final it = itemFromApiJson(
          r.data as Map<String, dynamic>,
          organizationId: orgId,
        );
        await db
            .into(db.localItems)
            .insertOnConflictUpdate(it.toCompanion(false));
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
              locationId: Value(fields.locationId),
              itemTypeId: Value(fields.itemTypeId),
              name: fields.name,
              notes: Value(fields.notes),
              isActive: Value(fields.isActive),
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
      locationId: fields.locationId,
      name: fields.name,
      notes: fields.notes,
      isActive: fields.isActive,
    );
    if (online) {
      try {
        final r = await restCall(
          () => dio.patch(
            '/v1/items/$id',
            data: {...body, 'version': ?baseVersion},
          ),
        );
        // `.toCompanion(false)` p/ o `insertOnConflictUpdate` conseguir limpar
        // `location_id` (desvincular item de um local).
        await db
            .into(db.localItems)
            .insertOnConflictUpdate(
              itemFromApiJson(
                r.data as Map<String, dynamic>,
                organizationId: orgId,
              ).toCompanion(false),
            );
        return;
      } on ApiException catch (e) {
        if (!isOfflineError(e)) rethrow;
      }
    }
    await db.transaction(() async {
      await (db.update(db.localItems)..where((t) => t.id.equals(id))).write(
        LocalItemsCompanion(
          locationId: Value(fields.locationId),
          itemTypeId: Value(fields.itemTypeId),
          name: Value(fields.name),
          notes: Value(fields.notes),
          isActive: Value(fields.isActive),
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
}

// ---------------------------------------------------------------------------

class RemoteItemRepository implements ItemRepository, PagedListRepository {
  RemoteItemRepository(Dio dio, String orgId)
    : _collection = RemoteCollection<LocalItem>(
        dio: dio,
        listPath: '/v1/items',
        listKey: 'items',
        fromJson: (j) => itemFromApiJson(j, organizationId: orgId),
        idOf: (i) => i.id,
        pageSize: 50,
      );

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
    required ItemFields fields,
  }) async {
    final it = await _collection.create(
      itemCreateBody(
        clientId: clientId,
        itemTypeId: fields.itemTypeId,
        locationId: fields.locationId,
        name: fields.name,
        notes: fields.notes,
        isActive: fields.isActive,
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
        locationId: fields.locationId,
        name: fields.name,
        notes: fields.notes,
        isActive: fields.isActive,
      ),
      'version': ?baseVersion,
    });
  }
}
