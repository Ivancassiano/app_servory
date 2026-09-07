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
import 'service_order_item_mapper.dart';
import 'service_order_mapper.dart';

/// Ver [ClientRepository] para o racional. Cobre o cabeçalho da ordem, as
/// ações nomeadas (`start`/`complete`/`reopen`, ADR-0018), os itens (laudo por
/// equipamento) e as peças.
abstract interface class ServiceOrderRepository {
  Stream<List<LocalServiceOrder>> watchList();
  Stream<LocalServiceOrder?> watchById(String id);
  Stream<List<LocalServiceOrderPart>> watchParts(String orderId);
  Stream<List<LocalServiceOrderItem>> watchItems(String orderId);
  Future<void> refresh();

  Future<String> addItem({
    required String orderId,
    String? itemId,
    String diagnosis = '',
    String workPerformed = '',
    String finalCondition = '',
    String note = '',
  });

  Future<void> updateItem({
    required String orderId,
    required String itemId,
    required int? baseVersion,
    required String diagnosis,
    required String workPerformed,
    required String finalCondition,
    required String note,
  });

  Future<void> deleteItem({required String orderId, required String itemId});

  Future<void> setItemApproval({
    required String orderId,
    required String itemId,
    required String approval,
  });

  /// Agenda a aplicação das correções: cria a ordem-filha (só itens aprovados)
  /// ligada a [parentOrderId]. Online-only (POST /v1/service-orders/{id}/follow-up).
  Future<String> createFollowUp({
    required String parentOrderId,
    DateTime? scheduledFor,
  });

  /// [mode] ∈ {`draft`, `open`, `start`} (spec §7.6). `start` já entra em
  /// andamento; `open` agenda/abre; `draft` salva rascunho.
  Future<String> create({
    required String clientId,
    String? itemId,
    String? serviceOrderTypeId,
    String? companyId,
    String? assignedUserId,
    DateTime? scheduledFor,
    required String mode,
    required String reason,
  });

  Future<void> update({
    required String id,
    required int? baseVersion,
    String? itemId,
    String? serviceOrderTypeId,
    String? companyId,
    String? assignedUserId,
    DateTime? scheduledFor,
    required String reason,
    required String diagnosis,
    required String workPerformed,
    required String finalCondition,
    required String notes,
  });

  /// `action` ∈ {start, complete, reopen}.
  Future<void> transition({
    required String id,
    required int? baseVersion,
    required String action,
  });

  Future<void> addPart({
    required String orderId,
    required String description,
    required String partNumber,
    required String quantity,
    required String unit,
    required String unitCost,
    required String unitPrice,
    required String notes,
    String? serviceOrderItemId,
  });

  Future<void> updatePart({
    required String orderId,
    required String partId,
    required int? baseVersion,
    required String description,
    required String partNumber,
    required String quantity,
    required String unit,
    required String unitCost,
    required String unitPrice,
    required String notes,
  });

  Future<void> deletePart({
    required String orderId,
    required String partId,
    required int? baseVersion,
  });
}

final serviceOrderRepositoryProvider = Provider<ServiceOrderRepository>((ref) {
  final orgId = ref.watch(organizationIdProvider);
  if (kIsWeb) {
    final repo = RemoteServiceOrderRepository(
      ref.watch(apiClientProvider).businessDio,
      orgId,
    );
    ref.onDispose(repo.dispose);
    return repo;
  }
  return LocalFirstServiceOrderRepository(ref);
});

// ---------------------------------------------------------------------------

/// Status local inicial para o modo de criação (o servidor faz o mesmo
/// mapeamento em `createStatus`).
String _statusForMode(String mode) => switch (mode) {
  'start' => 'in_progress',
  'open' => 'open',
  _ => 'draft',
};

class LocalFirstServiceOrderRepository extends LocalFirstRepositoryBase
    implements ServiceOrderRepository {
  LocalFirstServiceOrderRepository(super.ref);

  @override
  Stream<List<LocalServiceOrder>> watchList() {
    final q = db.select(db.localServiceOrders)
      ..where((t) => t.deleted.equals(false))
      ..orderBy([
        (t) => OrderingTerm(
          expression: t.localUpdatedAt,
          mode: OrderingMode.desc,
        ),
      ]);
    return q.watch();
  }

  @override
  Stream<LocalServiceOrder?> watchById(String id) =>
      (db.select(db.localServiceOrders)..where((t) => t.id.equals(id)))
          .watchSingleOrNull();

  @override
  Stream<List<LocalServiceOrderPart>> watchParts(String orderId) {
    final q = db.select(db.localServiceOrderParts)
      ..where(
        (t) => t.serviceOrderId.equals(orderId) & t.deleted.equals(false),
      )
      ..orderBy([(t) => OrderingTerm(expression: t.localUpdatedAt)]);
    return q.watch();
  }

  @override
  Stream<List<LocalServiceOrderItem>> watchItems(String orderId) {
    final q = db.select(db.localServiceOrderItems)
      ..where(
        (t) => t.serviceOrderId.equals(orderId) & t.deleted.equals(false),
      )
      ..orderBy([
        (t) => OrderingTerm(expression: t.position),
        (t) => OrderingTerm(expression: t.createdAt),
      ]);
    return q.watch();
  }

  @override
  Future<String> addItem({
    required String orderId,
    String? itemId,
    String diagnosis = '',
    String workPerformed = '',
    String finalCondition = '',
    String note = '',
  }) async {
    final body = serviceOrderItemBody(
      diagnosis: diagnosis,
      workPerformed: workPerformed,
      finalCondition: finalCondition,
      note: note,
    );
    if (online) {
      try {
        final r = await restCall(
          () => dio.post('/v1/service-orders/$orderId/items', data: body),
        );
        final item = serviceOrderItemFromApiJson(
          r.data as Map<String, dynamic>,
          organizationId: orgId,
        );
        await db.into(db.localServiceOrderItems).insertOnConflictUpdate(item);
        return item.id;
      } on ApiException catch (e) {
        if (!isOfflineError(e)) rethrow;
      }
    }
    final id = _uuid();
    await db.transaction(() async {
      await db.into(db.localServiceOrderItems).insert(
            LocalServiceOrderItemsCompanion.insert(
              id: id,
              organizationId: orgId,
              serviceOrderId: orderId,
              itemId: itemId ?? '',
              diagnosis: Value(diagnosis),
              workPerformed: Value(workPerformed),
              finalCondition: Value(finalCondition),
              note: Value(note),
              localUpdatedAt: DateTime.now(),
              syncStatus: const Value('pending'),
              lastSyncedAt: const Value(null),
            ),
          );
      await enqueue(
        entityType: 'service_order_item',
        entityId: id,
        operationType: 'create',
        payload: {...body, 'service_order_id': orderId},
      );
    });
    unawaited(trySyncNow());
    return id;
  }

  @override
  Future<void> updateItem({
    required String orderId,
    required String itemId,
    required int? baseVersion,
    required String diagnosis,
    required String workPerformed,
    required String finalCondition,
    required String note,
  }) async {
    final body = serviceOrderItemBody(
      diagnosis: diagnosis,
      workPerformed: workPerformed,
      finalCondition: finalCondition,
      note: note,
    );
    if (online) {
      try {
        final r = await restCall(
          () => dio.patch(
            '/v1/service-orders/$orderId/items/$itemId',
            data: {...body, 'version': ?baseVersion},
          ),
        );
        await db.into(db.localServiceOrderItems).insertOnConflictUpdate(
              serviceOrderItemFromApiJson(
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
      await (db.update(db.localServiceOrderItems)
            ..where((t) => t.id.equals(itemId)))
          .write(
        LocalServiceOrderItemsCompanion(
          diagnosis: Value(diagnosis),
          workPerformed: Value(workPerformed),
          finalCondition: Value(finalCondition),
          note: Value(note),
          localUpdatedAt: Value(DateTime.now()),
          syncStatus: const Value('pending'),
        ),
      );
      await enqueue(
        entityType: 'service_order_item',
        entityId: itemId,
        operationType: 'update',
        payload: body,
        baseVersion: baseVersion,
      );
    });
    unawaited(trySyncNow());
  }

  @override
  Future<void> deleteItem({
    required String orderId,
    required String itemId,
  }) async {
    if (online) {
      try {
        await restCall(
          () => dio.delete('/v1/service-orders/$orderId/items/$itemId'),
        );
        await (db.delete(db.localServiceOrderItems)
              ..where((t) => t.id.equals(itemId)))
            .go();
        return;
      } on ApiException catch (e) {
        if (!isOfflineError(e)) rethrow;
      }
    }
    await db.transaction(() async {
      await (db.update(db.localServiceOrderItems)
            ..where((t) => t.id.equals(itemId)))
          .write(
        const LocalServiceOrderItemsCompanion(
          deleted: Value(true),
          syncStatus: Value('pending'),
        ),
      );
      await enqueue(
        entityType: 'service_order_item',
        entityId: itemId,
        operationType: 'delete',
        payload: const {},
      );
    });
    unawaited(trySyncNow());
  }

  @override
  Future<void> setItemApproval({
    required String orderId,
    required String itemId,
    required String approval,
  }) async {
    // Aprovação é ação online (escritório, decisão do cliente) — sem fila.
    final r = await restCall(
      () => dio.post(
        '/v1/service-orders/$orderId/items/$itemId/approval',
        data: {'approval': approval},
      ),
    );
    await db.into(db.localServiceOrderItems).insertOnConflictUpdate(
          serviceOrderItemFromApiJson(
            r.data as Map<String, dynamic>,
            organizationId: orgId,
          ),
        );
  }

  @override
  Future<String> createFollowUp({
    required String parentOrderId,
    DateTime? scheduledFor,
  }) async {
    final r = await restCall(
      () => dio.post(
        '/v1/service-orders/$parentOrderId/follow-up',
        data: {'scheduled_for': ?scheduledFor?.toUtc().toIso8601String()},
      ),
    );
    final child = serviceOrderFromApiJson(
      r.data as Map<String, dynamic>,
      organizationId: orgId,
    );
    await db.into(db.localServiceOrders).insertOnConflictUpdate(child);
    unawaited(trySyncNow()); // puxa os itens copiados
    return child.id;
  }

  @override
  Future<void> refresh() => runSync();

  @override
  Future<String> create({
    required String clientId,
    String? itemId,
    String? serviceOrderTypeId,
    String? companyId,
    String? assignedUserId,
    DateTime? scheduledFor,
    required String mode,
    required String reason,
  }) async {
    final body = serviceOrderCreateBody(
      clientId: clientId,
      itemId: itemId,
      serviceOrderTypeId: serviceOrderTypeId,
      companyId: companyId,
      assignedUserId: assignedUserId,
      scheduledFor: scheduledFor,
      mode: mode,
      reason: reason,
    );
    if (online) {
      try {
        final r = await restCall(
          () => dio.post('/v1/service-orders', data: body),
        );
        final order = serviceOrderFromApiJson(
          r.data as Map<String, dynamic>,
          organizationId: orgId,
        );
        await db.into(db.localServiceOrders).insertOnConflictUpdate(order);
        return order.id;
      } on ApiException catch (e) {
        if (!isOfflineError(e)) rethrow;
      }
    }
    final id = _uuid();
    await db.transaction(() async {
      await db.into(db.localServiceOrders).insert(
            LocalServiceOrdersCompanion.insert(
              id: id,
              organizationId: orgId,
              clientId: clientId,
              itemId: Value(itemId),
              serviceOrderTypeId: Value(serviceOrderTypeId),
              companyId: Value(companyId),
              assignedUserId: Value(assignedUserId),
              scheduledFor: Value(scheduledFor),
              status: Value(_statusForMode(mode)),
              startedAt: Value(mode == 'start' ? DateTime.now() : null),
              reason: Value(reason),
              localUpdatedAt: DateTime.now(),
              syncStatus: const Value('pending'),
              lastSyncedAt: const Value(null),
            ),
          );
      await enqueue(
        entityType: 'service_order',
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
    String? itemId,
    String? serviceOrderTypeId,
    String? companyId,
    String? assignedUserId,
    DateTime? scheduledFor,
    required String reason,
    required String diagnosis,
    required String workPerformed,
    required String finalCondition,
    required String notes,
  }) async {
    final body = serviceOrderUpdateBody(
      itemId: itemId,
      serviceOrderTypeId: serviceOrderTypeId,
      companyId: companyId,
      assignedUserId: assignedUserId,
      scheduledFor: scheduledFor,
      reason: reason,
      diagnosis: diagnosis,
      workPerformed: workPerformed,
      finalCondition: finalCondition,
      notes: notes,
    );
    if (online) {
      try {
        final r = await restCall(
          () => dio.patch(
            '/v1/service-orders/$id',
            data: {...body, 'version': ?baseVersion},
          ),
        );
        await db.into(db.localServiceOrders).insertOnConflictUpdate(
              serviceOrderFromApiJson(
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
      await (db.update(db.localServiceOrders)..where((t) => t.id.equals(id)))
          .write(
        LocalServiceOrdersCompanion(
          itemId: itemId != null ? Value(itemId) : const Value.absent(),
          serviceOrderTypeId: serviceOrderTypeId != null
              ? Value(serviceOrderTypeId)
              : const Value.absent(),
          companyId: companyId != null
              ? Value(companyId)
              : const Value.absent(),
          assignedUserId: assignedUserId != null
              ? Value(assignedUserId)
              : const Value.absent(),
          scheduledFor: scheduledFor != null
              ? Value(scheduledFor)
              : const Value.absent(),
          reason: Value(reason),
          diagnosis: Value(diagnosis),
          workPerformed: Value(workPerformed),
          finalCondition: Value(finalCondition),
          notes: Value(notes),
          localUpdatedAt: Value(DateTime.now()),
          syncStatus: const Value('pending'),
        ),
      );
      await enqueue(
        entityType: 'service_order',
        entityId: id,
        operationType: 'update',
        payload: body,
        baseVersion: baseVersion,
      );
    });
    unawaited(trySyncNow());
  }

  @override
  Future<void> transition({
    required String id,
    required int? baseVersion,
    required String action,
  }) async {
    if (online) {
      try {
        final r = await restCall(
          () => dio.post(
            '/v1/service-orders/$id/$action',
            data: {'version': ?baseVersion},
          ),
        );
        await db.into(db.localServiceOrders).insertOnConflictUpdate(
              serviceOrderFromApiJson(
                r.data as Map<String, dynamic>,
                organizationId: orgId,
              ),
            );
        return;
      } on ApiException catch (e) {
        if (!isOfflineError(e)) rethrow;
      }
    }
    final now = DateTime.now();
    final (newStatus, startedAt, completedAt) = switch (action) {
      'start' => ('in_progress', Value(now), const Value<DateTime?>.absent()),
      'complete' => ('completed', const Value<DateTime?>.absent(), Value(now)),
      'reopen' => (
        'in_progress',
        const Value<DateTime?>.absent(),
        const Value<DateTime?>(null),
      ),
      _ => throw ArgumentError('transição inválida: $action'),
    };
    await db.transaction(() async {
      await (db.update(db.localServiceOrders)..where((t) => t.id.equals(id)))
          .write(
        LocalServiceOrdersCompanion(
          status: Value(newStatus),
          startedAt: startedAt,
          completedAt: completedAt,
          localUpdatedAt: Value(now),
          syncStatus: const Value('pending'),
        ),
      );
      await enqueue(
        entityType: 'service_order',
        entityId: id,
        operationType: action,
        payload: const {},
        baseVersion: baseVersion,
      );
    });
    unawaited(trySyncNow());
  }

  @override
  Future<void> addPart({
    required String orderId,
    required String description,
    required String partNumber,
    required String quantity,
    required String unit,
    required String unitCost,
    required String unitPrice,
    required String notes,
    String? serviceOrderItemId,
  }) async {
    final body = servicePartCreateBody(
      description: description,
      partNumber: partNumber,
      quantity: quantity,
      unit: unit,
      unitCost: unitCost,
      unitPrice: unitPrice,
      notes: notes,
      serviceOrderItemId: serviceOrderItemId,
    );
    if (online) {
      try {
        final r = await restCall(
          () => dio.post('/v1/service-orders/$orderId/parts', data: body),
        );
        await db.into(db.localServiceOrderParts).insertOnConflictUpdate(
              servicePartFromApiJson(
                r.data as Map<String, dynamic>,
                organizationId: orgId,
              ),
            );
        return;
      } on ApiException catch (e) {
        if (!isOfflineError(e)) rethrow;
      }
    }
    final id = _uuid();
    await db.transaction(() async {
      await db.into(db.localServiceOrderParts).insert(
            LocalServiceOrderPartsCompanion.insert(
              id: id,
              organizationId: orgId,
              serviceOrderId: orderId,
              serviceOrderItemId: Value(serviceOrderItemId),
              description: Value(description),
              partNumber: Value(partNumber),
              quantity: Value(quantity.isEmpty ? '1' : quantity),
              unit: Value(unit),
              unitCost: Value(unitCost.isEmpty ? null : unitCost),
              unitPrice: Value(unitPrice.isEmpty ? null : unitPrice),
              notes: Value(notes),
              localUpdatedAt: DateTime.now(),
              syncStatus: const Value('pending'),
              lastSyncedAt: const Value(null),
            ),
          );
      await enqueue(
        entityType: 'service_order_part',
        entityId: id,
        operationType: 'create',
        payload: {...body, 'service_order_id': orderId},
      );
    });
    unawaited(trySyncNow());
  }

  @override
  Future<void> updatePart({
    required String orderId,
    required String partId,
    required int? baseVersion,
    required String description,
    required String partNumber,
    required String quantity,
    required String unit,
    required String unitCost,
    required String unitPrice,
    required String notes,
  }) async {
    final body = servicePartUpdateBody(
      description: description,
      partNumber: partNumber,
      quantity: quantity,
      unit: unit,
      unitCost: unitCost,
      unitPrice: unitPrice,
      notes: notes,
    );
    if (online) {
      try {
        final r = await restCall(
          () => dio.patch(
            '/v1/service-orders/$orderId/parts/$partId',
            data: {...body, 'version': ?baseVersion},
          ),
        );
        await db.into(db.localServiceOrderParts).insertOnConflictUpdate(
              servicePartFromApiJson(
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
      await (db.update(db.localServiceOrderParts)
            ..where((t) => t.id.equals(partId)))
          .write(
        LocalServiceOrderPartsCompanion(
          description: Value(description),
          partNumber: Value(partNumber),
          quantity: Value(quantity.isEmpty ? '1' : quantity),
          unit: Value(unit),
          unitCost: Value(unitCost.isEmpty ? null : unitCost),
          unitPrice: Value(unitPrice.isEmpty ? null : unitPrice),
          notes: Value(notes),
          localUpdatedAt: Value(DateTime.now()),
          syncStatus: const Value('pending'),
        ),
      );
      await enqueue(
        entityType: 'service_order_part',
        entityId: partId,
        operationType: 'update',
        payload: body,
        baseVersion: baseVersion,
      );
    });
    unawaited(trySyncNow());
  }

  @override
  Future<void> deletePart({
    required String orderId,
    required String partId,
    required int? baseVersion,
  }) async {
    if (online) {
      try {
        await restCall(
          () => dio.delete('/v1/service-orders/$orderId/parts/$partId'),
        );
        await (db.delete(db.localServiceOrderParts)
              ..where((t) => t.id.equals(partId)))
            .go();
        return;
      } on ApiException catch (e) {
        if (!isOfflineError(e)) rethrow;
      }
    }
    await db.transaction(() async {
      await (db.update(db.localServiceOrderParts)
            ..where((t) => t.id.equals(partId)))
          .write(
        const LocalServiceOrderPartsCompanion(
          deleted: Value(true),
          syncStatus: Value('pending'),
        ),
      );
      await enqueue(
        entityType: 'service_order_part',
        entityId: partId,
        operationType: 'delete',
        payload: const {},
        baseVersion: baseVersion,
      );
    });
    unawaited(trySyncNow());
  }

  String _uuid() => const Uuid().v4();
}

// ---------------------------------------------------------------------------

class RemoteServiceOrderRepository implements ServiceOrderRepository {
  RemoteServiceOrderRepository(this._dio, this._orgId)
    : _orders = RemoteCollection<LocalServiceOrder>(
        dio: _dio,
        listPath: '/v1/service-orders',
        listKey: 'service_orders',
        fromJson: (j) => serviceOrderFromApiJson(j, organizationId: _orgId),
        idOf: (o) => o.id,
      );

  final Dio _dio;
  final String _orgId;
  final RemoteCollection<LocalServiceOrder> _orders;
  final _partsByOrder = <String, RemoteCollection<LocalServiceOrderPart>>{};

  RemoteCollection<LocalServiceOrderPart> _parts(String orderId) =>
      _partsByOrder.putIfAbsent(
        orderId,
        () => RemoteCollection<LocalServiceOrderPart>(
          dio: _dio,
          listPath: '/v1/service-orders/$orderId/parts',
          listKey: 'parts',
          fromJson: (j) =>
              servicePartFromApiJson(j, organizationId: _orgId),
          idOf: (p) => p.id,
        ),
      );

  void dispose() {
    _orders.dispose();
    for (final c in _partsByOrder.values) {
      c.dispose();
    }
    for (final c in _itemsByOrder.values) {
      c.dispose();
    }
  }

  @override
  Stream<List<LocalServiceOrder>> watchList() => _orders.watchList();

  @override
  Stream<LocalServiceOrder?> watchById(String id) => _orders.watchById(id);

  @override
  Stream<List<LocalServiceOrderPart>> watchParts(String orderId) =>
      _parts(orderId).watchList();

  @override
  Future<void> refresh() => _orders.refresh();

  @override
  Future<String> create({
    required String clientId,
    String? itemId,
    String? serviceOrderTypeId,
    String? companyId,
    String? assignedUserId,
    DateTime? scheduledFor,
    required String mode,
    required String reason,
  }) async {
    final order = await _orders.create(
      serviceOrderCreateBody(
        clientId: clientId,
        itemId: itemId,
        serviceOrderTypeId: serviceOrderTypeId,
        companyId: companyId,
        assignedUserId: assignedUserId,
        scheduledFor: scheduledFor,
        mode: mode,
        reason: reason,
      ),
    );
    return order.id;
  }

  @override
  Future<void> update({
    required String id,
    required int? baseVersion,
    String? itemId,
    String? serviceOrderTypeId,
    String? companyId,
    String? assignedUserId,
    DateTime? scheduledFor,
    required String reason,
    required String diagnosis,
    required String workPerformed,
    required String finalCondition,
    required String notes,
  }) async {
    await _orders.update(id, {
      ...serviceOrderUpdateBody(
        itemId: itemId,
        serviceOrderTypeId: serviceOrderTypeId,
        companyId: companyId,
        assignedUserId: assignedUserId,
        scheduledFor: scheduledFor,
        reason: reason,
        diagnosis: diagnosis,
        workPerformed: workPerformed,
        finalCondition: finalCondition,
        notes: notes,
      ),
      'version': ?baseVersion,
    });
  }

  @override
  Future<void> transition({
    required String id,
    required int? baseVersion,
    required String action,
  }) async {
    await _orders.action(id, action, {'version': ?baseVersion});
  }

  @override
  Future<void> addPart({
    required String orderId,
    required String description,
    required String partNumber,
    required String quantity,
    required String unit,
    required String unitCost,
    required String unitPrice,
    required String notes,
    String? serviceOrderItemId,
  }) async {
    await _parts(orderId).create(
      servicePartCreateBody(
        description: description,
        partNumber: partNumber,
        quantity: quantity,
        unit: unit,
        unitCost: unitCost,
        unitPrice: unitPrice,
        notes: notes,
        serviceOrderItemId: serviceOrderItemId,
      ),
    );
  }

  @override
  Future<void> updatePart({
    required String orderId,
    required String partId,
    required int? baseVersion,
    required String description,
    required String partNumber,
    required String quantity,
    required String unit,
    required String unitCost,
    required String unitPrice,
    required String notes,
  }) async {
    await _parts(orderId).update(partId, {
      ...servicePartUpdateBody(
        description: description,
        partNumber: partNumber,
        quantity: quantity,
        unit: unit,
        unitCost: unitCost,
        unitPrice: unitPrice,
        notes: notes,
      ),
      'version': ?baseVersion,
    });
  }

  @override
  Future<void> deletePart({
    required String orderId,
    required String partId,
    required int? baseVersion,
  }) async {
    await _parts(orderId).remove(partId);
  }

  final _itemsByOrder = <String, RemoteCollection<LocalServiceOrderItem>>{};

  RemoteCollection<LocalServiceOrderItem> _items(String orderId) =>
      _itemsByOrder.putIfAbsent(
        orderId,
        () => RemoteCollection<LocalServiceOrderItem>(
          dio: _dio,
          listPath: '/v1/service-orders/$orderId/items',
          listKey: 'items',
          fromJson: (j) => serviceOrderItemFromApiJson(j, organizationId: _orgId),
          idOf: (i) => i.id,
        ),
      );

  @override
  Stream<List<LocalServiceOrderItem>> watchItems(String orderId) =>
      _items(orderId).watchList();

  @override
  Future<String> addItem({
    required String orderId,
    String? itemId,
    String diagnosis = '',
    String workPerformed = '',
    String finalCondition = '',
    String note = '',
  }) async {
    final it = await _items(orderId).create(
      serviceOrderItemBody(
        itemId: itemId,
        diagnosis: diagnosis,
        workPerformed: workPerformed,
        finalCondition: finalCondition,
        note: note,
      ),
    );
    return it.id;
  }

  @override
  Future<void> updateItem({
    required String orderId,
    required String itemId,
    required int? baseVersion,
    required String diagnosis,
    required String workPerformed,
    required String finalCondition,
    required String note,
  }) async {
    await _items(orderId).update(itemId, {
      ...serviceOrderItemBody(
        diagnosis: diagnosis,
        workPerformed: workPerformed,
        finalCondition: finalCondition,
        note: note,
      ),
      'version': ?baseVersion,
    });
  }

  @override
  Future<void> deleteItem({
    required String orderId,
    required String itemId,
  }) async {
    await _items(orderId).remove(itemId);
  }

  @override
  Future<void> setItemApproval({
    required String orderId,
    required String itemId,
    required String approval,
  }) async {
    await _items(orderId).action(itemId, 'approval', {'approval': approval});
  }

  @override
  Future<String> createFollowUp({
    required String parentOrderId,
    DateTime? scheduledFor,
  }) async {
    final r = await restCall(
      () => _dio.post(
        '/v1/service-orders/$parentOrderId/follow-up',
        data: {'scheduled_for': ?scheduledFor?.toUtc().toIso8601String()},
      ),
    );
    return (r.data as Map<String, dynamic>)['id'] as String;
  }
}
