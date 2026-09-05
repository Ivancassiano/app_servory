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
import 'service_order_mapper.dart';

/// Ver [ClientRepository] para o racional. Cobre o cabeçalho da ordem, as
/// ações nomeadas (`start`/`complete`/`reopen`, ADR-0018) e as peças.
abstract interface class ServiceOrderRepository {
  Stream<List<LocalServiceOrder>> watchList();
  Stream<LocalServiceOrder?> watchById(String id);
  Stream<List<LocalServiceOrderPart>> watchParts(String orderId);
  Future<void> refresh();

  Future<String> create({
    required String clientId,
    String? locationId,
    String? equipmentId,
    required bool open,
    required String reason,
  });

  Future<void> update({
    required String id,
    required int? baseVersion,
    String? locationId,
    String? equipmentId,
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
  Future<void> refresh() => runSync();

  @override
  Future<String> create({
    required String clientId,
    String? locationId,
    String? equipmentId,
    required bool open,
    required String reason,
  }) async {
    final body = serviceOrderCreateBody(
      clientId: clientId,
      locationId: locationId,
      equipmentId: equipmentId,
      open: open,
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
              locationId: Value(locationId),
              equipmentId: Value(equipmentId),
              status: Value(open ? 'open' : 'draft'),
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
    String? locationId,
    String? equipmentId,
    required String reason,
    required String diagnosis,
    required String workPerformed,
    required String finalCondition,
    required String notes,
  }) async {
    final body = serviceOrderUpdateBody(
      locationId: locationId,
      equipmentId: equipmentId,
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
  }) async {
    final body = servicePartCreateBody(
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
    String? locationId,
    String? equipmentId,
    required bool open,
    required String reason,
  }) async {
    final order = await _orders.create(
      serviceOrderCreateBody(
        clientId: clientId,
        locationId: locationId,
        equipmentId: equipmentId,
        open: open,
        reason: reason,
      ),
    );
    return order.id;
  }

  @override
  Future<void> update({
    required String id,
    required int? baseVersion,
    String? locationId,
    String? equipmentId,
    required String reason,
    required String diagnosis,
    required String workPerformed,
    required String finalCondition,
    required String notes,
  }) async {
    await _orders.update(id, {
      ...serviceOrderUpdateBody(
        locationId: locationId,
        equipmentId: equipmentId,
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
}
