import 'dart:convert';

import 'package:drift/drift.dart' show Value;

import '../../../core/db/app_database.dart';
import '../../clients/data/client_mapper.dart';
import '../../equipments/data/equipment_mapper.dart';
import '../../labels/data/qr_mapper.dart';
import '../../locations/data/location_mapper.dart';
import '../../service_orders/data/service_order_mapper.dart';
import '../data/sync_api.dart';

/// As 7 entidades sincronizáveis (GUIA-FLUTTER.md §8.4) — `bootstrap`/`pull`
/// leem todas; `push` só as que têm operações de escrita. `qr_batch` é
/// somente leitura; `qr_code` não usa `version` de verdade (§9.3).
const _readEntityTypes = [
  'client',
  'location',
  'equipment',
  'service_order',
  'service_order_part',
  'qr_code',
  'qr_batch',
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
    var maxCursor = 0;
    for (final entityType in _readEntityTypes) {
      var page = 1;
      while (true) {
        final result = await _api.bootstrap(entityType: entityType, page: page);
        for (final item in result.items) {
          await _upsert(entityType, item);
        }
        // Cada bootstrap de entidade tira sua foto num instante diferente;
        // o `pull` seguinte deve partir da marca mais alta vista (reprocessar
        // é idempotente; pular uma mudança não é).
        if (result.cursor > maxCursor) maxCursor = result.cursor;
        if (!result.hasMore) break;
        page++;
      }
    }
    await _saveCursor(maxCursor);
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
      case 'qr_code':
        // A etiqueta certa vem no próximo `pull` (§9.4); aqui só limpamos o
        // estado pendente da linha que enviamos.
        await (_db.update(
          _db.localQrCodes,
        )..where((t) => t.id.equals(entityId))).write(
          LocalQrCodesCompanion(
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
      case 'qr_code':
        await (_db.update(
          _db.localQrCodes,
        )..where((t) => t.id.equals(entityId))).write(
          LocalQrCodesCompanion(syncStatus: status, syncError: error),
        );
    }
  }

  /// Grava o estado atual de uma entidade vindo de `pull`/`bootstrap`. O
  /// mapeamento JSON→`Local*` é o mesmo do caminho REST direto
  /// (`lib/features/*/data/*_mapper.dart`) — o shape é idêntico.
  Future<void> _upsert(String entityType, Map<String, dynamic> data) async {
    final org = _organizationId;
    switch (entityType) {
      case 'client':
        await _db
            .into(_db.localClients)
            .insertOnConflictUpdate(
              clientFromApiJson(data, organizationId: org),
            );
      case 'location':
        await _db
            .into(_db.localLocations)
            .insertOnConflictUpdate(
              locationFromApiJson(data, organizationId: org),
            );
      case 'equipment':
        await _db
            .into(_db.localEquipments)
            .insertOnConflictUpdate(
              equipmentFromApiJson(data, organizationId: org),
            );
      case 'service_order':
        await _db
            .into(_db.localServiceOrders)
            .insertOnConflictUpdate(
              serviceOrderFromApiJson(data, organizationId: org),
            );
      case 'service_order_part':
        await _db
            .into(_db.localServiceOrderParts)
            .insertOnConflictUpdate(
              servicePartFromApiJson(data, organizationId: org),
            );
      case 'qr_code':
        await _db
            .into(_db.localQrCodes)
            .insertOnConflictUpdate(
              qrCodeFromApiJson(data, organizationId: org),
            );
      case 'qr_batch':
        await _db
            .into(_db.localQrBatches)
            .insertOnConflictUpdate(
              qrBatchFromApiJson(data, organizationId: org),
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
      case 'qr_code':
        await (_db.update(_db.localQrCodes)
              ..where((t) => t.id.equals(entityId)))
            .write(const LocalQrCodesCompanion(deleted: Value(true)));
      case 'qr_batch':
        await (_db.update(_db.localQrBatches)
              ..where((t) => t.id.equals(entityId)))
            .write(const LocalQrBatchesCompanion(deleted: Value(true)));
    }
  }

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
