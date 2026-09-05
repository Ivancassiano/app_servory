import 'dart:convert';

import 'package:drift/drift.dart' show Value;

import '../../../core/db/app_database.dart';
import '../data/sync_api.dart';

/// As 3 entidades desta entrega (GUIA-FLUTTER.md §8.4) — `bootstrap`/`pull`
/// leem as 3; `push` só escreve `client` de volta (spec §7.6 "criar/editar
/// offline" fica pra próxima fatia nas outras duas).
const _readEntityTypes = ['client', 'location', 'equipment'];

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

  /// Envia a outbox pendente. Só `client` está ligado nesta entrega —
  /// `location`/`equipment` ficam só-leitura por ora (contexto no plano).
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
        await (_db.update(
          _db.localClients,
        )..where((t) => t.id.equals(op.entityId))).write(
          LocalClientsCompanion(
            version: Value(result.version),
            syncStatus: const Value('synced'),
            lastSyncedAt: Value(DateTime.now()),
            syncError: const Value(null),
          ),
        );
        await (_db.delete(
          _db.syncOutbox,
        )..where((t) => t.operationId.equals(op.operationId))).go();
      } else {
        await (_db.update(
          _db.localClients,
        )..where((t) => t.id.equals(op.entityId))).write(
          LocalClientsCompanion(
            syncStatus: Value(result.conflict ? 'conflict' : 'pending'),
            syncError: Value(result.errorCode),
          ),
        );
        if (!result.conflict)
          continue; // erro transitório: mantém na outbox p/ tentar de novo
        await (_db.delete(
          _db.syncOutbox,
        )..where((t) => t.operationId.equals(op.operationId))).go();
      }
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
