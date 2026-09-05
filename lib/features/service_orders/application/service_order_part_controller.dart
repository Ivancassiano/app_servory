import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/db/app_database.dart';
import '../../auth/application/session_controller.dart';
import '../../sync/application/sync_provider.dart';

/// Peças/materiais de uma ordem, mesmo molde local-primeiro dos demais
/// controllers. `unitCost`/`unitPrice` são sensíveis (grupo `cost`) — o app
/// não verifica permissão de escrita antes de mandar (mesma dívida já
/// registrada para `internal_notes`/`serial_number`/`cost`); um 422 do
/// servidor por falta de `service_order_part.cost.write` aparece como
/// conflito genérico, igual qualquer outro erro de push.
class ServiceOrderPartController {
  ServiceOrderPartController(this._ref);
  final Ref _ref;

  AppDatabase get _db => _ref.read(appDatabaseProvider);

  String get _organizationId {
    final session = _ref.read(sessionControllerProvider);
    if (session is! SessionAuthenticated) {
      throw StateError(
        'ServiceOrderPartController usado sem sessão autenticada',
      );
    }
    return session.organizationId;
  }

  Future<void> addPart({
    required String serviceOrderId,
    required String description,
    required String partNumber,
    required String quantity,
    required String unit,
    required String unitCost,
    required String unitPrice,
    required String notes,
  }) async {
    final organizationId = _organizationId;
    final now = DateTime.now();
    final id = const Uuid().v4();

    await _db.transaction(() async {
      await _db
          .into(_db.localServiceOrderParts)
          .insert(
            LocalServiceOrderPartsCompanion.insert(
              id: id,
              organizationId: organizationId,
              serviceOrderId: serviceOrderId,
              description: Value(description),
              partNumber: Value(partNumber),
              quantity: Value(quantity.isEmpty ? '1' : quantity),
              unit: Value(unit),
              unitCost: Value(unitCost.isEmpty ? null : unitCost),
              unitPrice: Value(unitPrice.isEmpty ? null : unitPrice),
              notes: Value(notes),
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
              entityType: 'service_order_part',
              entityId: id,
              operationType: 'create',
              payload: jsonEncode({
                'service_order_id': serviceOrderId,
                'description': description,
                'part_number': partNumber,
                'quantity': quantity.isEmpty ? '1' : quantity,
                'unit': unit,
                'unit_cost': unitCost,
                'unit_price': unitPrice,
                'notes': notes,
              }),
              occurredAt: now,
            ),
          );
    });

    unawaited(_trySyncNow());
  }

  Future<void> updatePart({
    required String partId,
    required String description,
    required String partNumber,
    required String quantity,
    required String unit,
    required String unitCost,
    required String unitPrice,
    required String notes,
  }) async {
    final organizationId = _organizationId;
    final now = DateTime.now();

    await _db.transaction(() async {
      final current = await (_db.select(
        _db.localServiceOrderParts,
      )..where((t) => t.id.equals(partId))).getSingle();

      await (_db.update(
        _db.localServiceOrderParts,
      )..where((t) => t.id.equals(partId))).write(
        LocalServiceOrderPartsCompanion(
          description: Value(description),
          partNumber: Value(partNumber),
          quantity: Value(quantity.isEmpty ? '1' : quantity),
          unit: Value(unit),
          unitCost: Value(unitCost.isEmpty ? null : unitCost),
          unitPrice: Value(unitPrice.isEmpty ? null : unitPrice),
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
              entityType: 'service_order_part',
              entityId: partId,
              operationType: 'update',
              payload: jsonEncode({
                'description': description,
                'part_number': partNumber,
                'quantity': quantity.isEmpty ? '1' : quantity,
                'unit': unit,
                'unit_cost': unitCost,
                'unit_price': unitPrice,
                'notes': notes,
              }),
              baseVersion: Value(current.version),
              occurredAt: now,
            ),
          );
    });

    unawaited(_trySyncNow());
  }

  Future<void> deletePart(String partId) async {
    final organizationId = _organizationId;
    final now = DateTime.now();

    await _db.transaction(() async {
      final current = await (_db.select(
        _db.localServiceOrderParts,
      )..where((t) => t.id.equals(partId))).getSingle();

      await (_db.update(
        _db.localServiceOrderParts,
      )..where((t) => t.id.equals(partId))).write(
        const LocalServiceOrderPartsCompanion(
          deleted: Value(true),
          syncStatus: Value('pending'),
        ),
      );
      await _db
          .into(_db.syncOutbox)
          .insert(
            SyncOutboxCompanion.insert(
              operationId: const Uuid().v4(),
              organizationId: organizationId,
              entityType: 'service_order_part',
              entityId: partId,
              operationType: 'delete',
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

final serviceOrderPartControllerProvider = Provider<ServiceOrderPartController>(
  (ref) => ServiceOrderPartController(ref),
);
