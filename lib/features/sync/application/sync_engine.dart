import 'dart:convert';

import 'package:drift/drift.dart' show Value;

import '../../../core/db/app_database.dart';
import '../data/sync_api.dart';

/// As 3 entidades desta entrega (GUIA-FLUTTER.md §8.4) — `bootstrap`/`pull`/
/// `push` tratam as 3 igual.
const _readEntityTypes = [
  'client',
  'location',
  'equipment',
  'service_order',
  'service_order_part',
];

/// Orquestra `bootstrap`/`pull`/`push` entre o [SyncApi] e o [AppDatabase]
/// local. Sem regra de negócio aqui — só tradução de shape (igual
/// `internal/sync` no backend, ADR-0014).
class SyncEngine {
  SyncEngine({
    required SyncApi api,
    required AppDatabase db,
    required String organizationId,
  }) : _api = api,
       _db = db,
       _organizationId = organizationId;

  final SyncApi _api;
  final AppDatabase _db;
  final String _organizationId;

  /// Dump completo paginado, uma vez por organização (quando o banco local
  /// ainda não tinha nada) — GUIA-FLUTTER.md §8.2.
  Future<void> bootstrap() async {
    int? finalCursor;
    for (final entityType in _readEntityTypes) {
      var page = 1;
      while (true) {
        final result = await _api.bootstrap(entityType: entityType, page: page);
        for (final item in result.items) {
          await _upsert(entityType, item);
        }
        finalCursor = result.cursor;
        if (!result.hasMore) break;
        page++;
      }
    }
    await _saveCursor(finalCursor ?? 0);
  }

  /// Mudanças desde o cursor salvo, em loop até `next_cursor` parar de
  /// avançar (GUIA-FLUTTER.md §8.2).
  Future<void> pull() async {
    var cursor = await _readCursor();
    while (true) {
      final result = await _api.pull(cursor: cursor);
      for (final change in result.entities) {
        if (!_readEntityTypes.contains(change.entityType)) continue;
        if (change.deleted) {
          await _softDelete(change.entityType, change.entityId);
        } else if (change.data != null) {
          await _upsert(change.entityType, change.data!);
        }
      }

      final stalled = result.entities.isEmpty || result.nextCursor == cursor;
      cursor = result.nextCursor;
      await _saveCursor(cursor);
      if (stalled) break;
    }
  }

  /// Envia a outbox pendente. As 3 entidades passam por aqui igual —
  /// `entityType` decide em qual tabela local o resultado é gravado.
  Future<void> pushPending() async {
    final pending = await _db.select(_db.syncOutbox).get();
    if (pending.isEmpty) return;

    final operations = pending
        .map(
          (row) => SyncOperationRequest(
            operationId: row.operationId,
            entityType: row.entityType,
            entityId: row.entityId,
            operationType: row.operationType,
            baseVersion: row.baseVersion,
            payload: jsonDecode(row.payload) as Map<String, dynamic>,
          ),
        )
        .toList();

    final results = await _api.push(operations);

    for (final result in results) {
      final op = pending.firstWhere((p) => p.operationId == result.operationId);
      if (result.accepted) {
        await _markSynced(op.entityType, op.entityId, result.version);
        await (_db.delete(
          _db.syncOutbox,
        )..where((t) => t.operationId.equals(op.operationId))).go();
      } else {
        await _markPushFailed(
          op.entityType,
          op.entityId,
          result.conflict,
          result.errorCode,
        );
        if (!result.conflict)
          continue; // erro transitório: mantém na outbox p/ tentar de novo
        await (_db.delete(
          _db.syncOutbox,
        )..where((t) => t.operationId.equals(op.operationId))).go();
      }
    }
  }

  Future<void> _markSynced(
    String entityType,
    String entityId,
    int? version,
  ) async {
    final now = DateTime.now();
    switch (entityType) {
      case 'client':
        await (_db.update(
          _db.localClients,
        )..where((t) => t.id.equals(entityId))).write(
          LocalClientsCompanion(
            version: Value(version),
            syncStatus: const Value('synced'),
            lastSyncedAt: Value(now),
            syncError: const Value(null),
          ),
        );
      case 'location':
        await (_db.update(
          _db.localLocations,
        )..where((t) => t.id.equals(entityId))).write(
          LocalLocationsCompanion(
            version: Value(version),
            syncStatus: const Value('synced'),
            lastSyncedAt: Value(now),
            syncError: const Value(null),
          ),
        );
      case 'equipment':
        await (_db.update(
          _db.localEquipments,
        )..where((t) => t.id.equals(entityId))).write(
          LocalEquipmentsCompanion(
            version: Value(version),
            syncStatus: const Value('synced'),
            lastSyncedAt: Value(now),
            syncError: const Value(null),
          ),
        );
      case 'service_order':
        await (_db.update(
          _db.localServiceOrders,
        )..where((t) => t.id.equals(entityId))).write(
          LocalServiceOrdersCompanion(
            version: Value(version),
            syncStatus: const Value('synced'),
            lastSyncedAt: Value(now),
            syncError: const Value(null),
          ),
        );
      case 'service_order_part':
        await (_db.update(
          _db.localServiceOrderParts,
        )..where((t) => t.id.equals(entityId))).write(
          LocalServiceOrderPartsCompanion(
            version: Value(version),
            syncStatus: const Value('synced'),
            lastSyncedAt: Value(now),
            syncError: const Value(null),
          ),
        );
    }
  }

  Future<void> _markPushFailed(
    String entityType,
    String entityId,
    bool conflict,
    String? errorCode,
  ) async {
    final status = Value(conflict ? 'conflict' : 'pending');
    final error = Value(errorCode);
    switch (entityType) {
      case 'client':
        await (_db.update(_db.localClients)
              ..where((t) => t.id.equals(entityId)))
            .write(LocalClientsCompanion(syncStatus: status, syncError: error));
      case 'location':
        await (_db.update(
          _db.localLocations,
        )..where((t) => t.id.equals(entityId))).write(
          LocalLocationsCompanion(syncStatus: status, syncError: error),
        );
      case 'equipment':
        await (_db.update(
          _db.localEquipments,
        )..where((t) => t.id.equals(entityId))).write(
          LocalEquipmentsCompanion(syncStatus: status, syncError: error),
        );
      case 'service_order':
        await (_db.update(
          _db.localServiceOrders,
        )..where((t) => t.id.equals(entityId))).write(
          LocalServiceOrdersCompanion(syncStatus: status, syncError: error),
        );
      case 'service_order_part':
        await (_db.update(
          _db.localServiceOrderParts,
        )..where((t) => t.id.equals(entityId))).write(
          LocalServiceOrderPartsCompanion(syncStatus: status, syncError: error),
        );
    }
  }

  Future<void> _upsert(String entityType, Map<String, dynamic> data) async {
    final now = DateTime.now();
    switch (entityType) {
      case 'client':
        await _db
            .into(_db.localClients)
            .insertOnConflictUpdate(
              LocalClientsCompanion.insert(
                id: data['id'] as String,
                organizationId: _organizationId,
                kind: data['kind'] as String? ?? 'legal',
                name: data['name'] as String? ?? '',
                legalName: Value(data['legal_name'] as String? ?? ''),
                taxId: Value(data['tax_id'] as String? ?? ''),
                phone: Value(data['phone'] as String? ?? ''),
                email: Value(data['email'] as String? ?? ''),
                contactPerson: Value(data['contact_person'] as String? ?? ''),
                internalNotes: Value(data['internal_notes'] as String?),
                version: Value(data['version'] as int?),
                createdAt: Value(_parseDate(data['created_at'])),
                updatedAt: Value(_parseDate(data['updated_at'])),
                localUpdatedAt: now,
                syncStatus: const Value('synced'),
                lastSyncedAt: Value(now),
                deleted: const Value(false),
              ),
            );
      case 'location':
        await _db
            .into(_db.localLocations)
            .insertOnConflictUpdate(
              LocalLocationsCompanion.insert(
                id: data['id'] as String,
                organizationId: _organizationId,
                clientId: data['client_id'] as String? ?? '',
                parentLocationId: Value(data['parent_location_id'] as String?),
                name: data['name'] as String? ?? '',
                postalCode: Value(data['postal_code'] as String? ?? ''),
                street: Value(data['street'] as String? ?? ''),
                number: Value(data['number'] as String? ?? ''),
                complement: Value(data['complement'] as String? ?? ''),
                district: Value(data['district'] as String? ?? ''),
                city: Value(data['city'] as String? ?? ''),
                state: Value(data['state'] as String? ?? ''),
                contactPerson: Value(data['contact_person'] as String? ?? ''),
                phone: Value(data['phone'] as String? ?? ''),
                accessInstructions: Value(
                  data['access_instructions'] as String? ?? '',
                ),
                notes: Value(data['notes'] as String? ?? ''),
                version: Value(data['version'] as int?),
                createdAt: Value(_parseDate(data['created_at'])),
                updatedAt: Value(_parseDate(data['updated_at'])),
                localUpdatedAt: now,
                syncStatus: const Value('synced'),
                lastSyncedAt: Value(now),
                deleted: const Value(false),
              ),
            );
      case 'equipment':
        await _db
            .into(_db.localEquipments)
            .insertOnConflictUpdate(
              LocalEquipmentsCompanion.insert(
                id: data['id'] as String,
                organizationId: _organizationId,
                locationId: data['location_id'] as String? ?? '',
                equipmentTypeId: data['equipment_type_id'] as String? ?? '',
                name: data['name'] as String? ?? '',
                brand: Value(data['brand'] as String? ?? ''),
                model: Value(data['model'] as String? ?? ''),
                serialNumber: Value(data['serial_number'] as String?),
                internalLocation: Value(
                  data['internal_location'] as String? ?? '',
                ),
                installedAt: Value(data['installed_at'] as String?),
                cost: Value(data['cost'] as String?),
                notes: Value(data['notes'] as String? ?? ''),
                version: Value(data['version'] as int?),
                createdAt: Value(_parseDate(data['created_at'])),
                updatedAt: Value(_parseDate(data['updated_at'])),
                localUpdatedAt: now,
                syncStatus: const Value('synced'),
                lastSyncedAt: Value(now),
                deleted: const Value(false),
              ),
            );
      case 'service_order':
        await _db
            .into(_db.localServiceOrders)
            .insertOnConflictUpdate(
              LocalServiceOrdersCompanion.insert(
                id: data['id'] as String,
                organizationId: _organizationId,
                clientId: data['client_id'] as String? ?? '',
                locationId: Value(data['location_id'] as String?),
                equipmentId: Value(data['equipment_id'] as String?),
                serviceOrderTypeId: Value(
                  data['service_order_type_id'] as String?,
                ),
                companyId: Value(data['company_id'] as String?),
                assignedUserId: Value(data['assigned_user_id'] as String?),
                status: Value(data['status'] as String? ?? 'draft'),
                reason: Value(data['reason'] as String? ?? ''),
                diagnosis: Value(data['diagnosis'] as String? ?? ''),
                workPerformed: Value(data['work_performed'] as String? ?? ''),
                recommendations: Value(
                  data['recommendations'] as String? ?? '',
                ),
                finalCondition: Value(data['final_condition'] as String? ?? ''),
                notes: Value(data['notes'] as String? ?? ''),
                scheduledFor: Value(_parseDate(data['scheduled_for'])),
                startedAt: Value(_parseDate(data['started_at'])),
                completedAt: Value(_parseDate(data['completed_at'])),
                version: Value(data['version'] as int?),
                createdAt: Value(_parseDate(data['created_at'])),
                updatedAt: Value(_parseDate(data['updated_at'])),
                localUpdatedAt: now,
                syncStatus: const Value('synced'),
                lastSyncedAt: Value(now),
                deleted: const Value(false),
              ),
            );
      case 'service_order_part':
        await _db
            .into(_db.localServiceOrderParts)
            .insertOnConflictUpdate(
              LocalServiceOrderPartsCompanion.insert(
                id: data['id'] as String,
                organizationId: _organizationId,
                serviceOrderId: data['service_order_id'] as String? ?? '',
                description: Value(data['description'] as String? ?? ''),
                partNumber: Value(data['part_number'] as String? ?? ''),
                quantity: Value(data['quantity']?.toString() ?? '1'),
                unit: Value(data['unit'] as String? ?? ''),
                unitCost: Value(data['unit_cost']?.toString()),
                unitPrice: Value(data['unit_price']?.toString()),
                notes: Value(data['notes'] as String? ?? ''),
                version: Value(data['version'] as int?),
                createdAt: Value(_parseDate(data['created_at'])),
                updatedAt: Value(_parseDate(data['updated_at'])),
                localUpdatedAt: now,
                syncStatus: const Value('synced'),
                lastSyncedAt: Value(now),
                deleted: const Value(false),
              ),
            );
    }
  }

  Future<void> _softDelete(String entityType, String entityId) async {
    switch (entityType) {
      case 'client':
        await (_db.update(_db.localClients)
              ..where((t) => t.id.equals(entityId)))
            .write(const LocalClientsCompanion(deleted: Value(true)));
      case 'location':
        await (_db.update(_db.localLocations)
              ..where((t) => t.id.equals(entityId)))
            .write(const LocalLocationsCompanion(deleted: Value(true)));
      case 'equipment':
        await (_db.update(_db.localEquipments)
              ..where((t) => t.id.equals(entityId)))
            .write(const LocalEquipmentsCompanion(deleted: Value(true)));
      case 'service_order':
        await (_db.update(_db.localServiceOrders)
              ..where((t) => t.id.equals(entityId)))
            .write(const LocalServiceOrdersCompanion(deleted: Value(true)));
      case 'service_order_part':
        await (_db.update(_db.localServiceOrderParts)
              ..where((t) => t.id.equals(entityId)))
            .write(const LocalServiceOrderPartsCompanion(deleted: Value(true)));
    }
  }

  DateTime? _parseDate(Object? value) =>
      value == null ? null : DateTime.tryParse(value as String);

  Future<int> _readCursor() async {
    final row =
        await (_db.select(_db.localSyncState)
              ..where((t) => t.organizationId.equals(_organizationId)))
            .getSingleOrNull();
    return row?.cursor ?? 0;
  }

  Future<void> _saveCursor(int cursor) async {
    await _db
        .into(_db.localSyncState)
        .insertOnConflictUpdate(
          LocalSyncStateCompanion.insert(
            organizationId: _organizationId,
            cursor: Value(cursor),
          ),
        );
  }
}
