// Campos privados vindos de parâmetro nomeado público — o padrão do projeto
// (ver remote_collection.dart) é atribuir na lista de inicialização.
// ignore_for_file: prefer_initializing_formals
import 'dart:convert';

import 'package:drift/drift.dart' show Value;

import '../../../core/db/app_database.dart';
import '../../clients/data/client_mapper.dart';
import '../../items/data/item_field_value_mapper.dart';
import '../../items/data/item_mapper.dart';
import '../../locations/data/location_mapper.dart';
import '../../labels/data/qr_mapper.dart';
import '../../service_orders/data/recommendation_mapper.dart';
import '../../service_orders/data/service_order_item_mapper.dart';
import '../../service_orders/data/service_order_mapper.dart';
import '../../tasks/data/task_mapper.dart';
import '../data/sync_api.dart';

/// As entidades sincronizáveis (GUIA-FLUTTER.md §8.4) — `bootstrap`/`pull`
/// leem todas; `push` só as que têm operações de escrita. `qr_batch` é
/// somente leitura; `qr_code` não usa `version` de verdade (§9.3).
const _readEntityTypes = [
  'client',
  'location',
  'item',
  'item_field_value',
  'service_order',
  'service_order_item',
  'service_order_part',
  'service_order_recommendation',
  'task',
  'qr_code',
  'qr_batch',
];

/// Tabela local de cada `entity_type` da outbox — para descartar/limpar o
/// estado pendente de uma operação sem um `switch` gigante.
const _entityTables = {
  'client': 'local_clients',
  'location': 'local_locations',
  'item': 'local_items',
  'item_field_value': 'local_item_field_values',
  'service_order': 'local_service_orders',
  'service_order_item': 'local_service_order_items',
  'service_order_part': 'local_service_order_parts',
  'service_order_recommendation': 'local_service_order_recommendations',
  'task': 'local_tasks',
  'qr_code': 'local_qr_codes',
  'qr_batch': 'local_qr_batches',
};

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

  /// Descarta uma operação presa na outbox — o que o usuário fez offline é
  /// perdido. Se for um `create` que nunca chegou ao servidor, apaga também a
  /// linha local; senão só tira a marca de "pendente/conflito" e deixa o
  /// próximo `pull` trazer o estado do servidor.
  Future<void> discardOperation(String operationId) async {
    final row = await (_db.select(_db.syncOutbox)
          ..where((t) => t.operationId.equals(operationId)))
        .getSingleOrNull();
    if (row == null) return;
    await (_db.delete(_db.syncOutbox)
          ..where((t) => t.operationId.equals(operationId)))
        .go();

    final table = _entityTables[row.entityType];
    if (table == null) return; // nome de tabela é constante (não é input)
    if (row.operationType == 'create') {
      await _db.customStatement('DELETE FROM $table WHERE id = ?', [
        row.entityId,
      ]);
    } else {
      await _db.customStatement(
        "UPDATE $table SET sync_status = 'synced', sync_error = NULL "
        'WHERE id = ?',
        [row.entityId],
      );
    }
  }

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
        if (result.conflict) {
          await (_db.delete(
            _db.syncOutbox,
          )..where((t) => t.operationId.equals(op.operationId))).go();
          continue;
        }
        // Erro não-conflito (validação, permissão, entidade sumiu): mantém na
        // outbox para tentar de novo, mas registra o motivo/tentativas para a
        // tela "Alterações pendentes" mostrar e o usuário poder descartar.
        await (_db.update(_db.syncOutbox)
              ..where((t) => t.operationId.equals(op.operationId)))
            .write(
              SyncOutboxCompanion(
                attempts: Value(op.attempts + 1),
                lastError: Value(result.errorCode ?? 'REJECTED'),
              ),
            );
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
      case 'item':
        await (_db.update(
          _db.localItems,
        )..where((t) => t.id.equals(entityId))).write(
          LocalItemsCompanion(
            version: Value(version),
            syncStatus: const Value('synced'),
            lastSyncedAt: Value(now),
            syncError: const Value(null),
          ),
        );
      case 'item_field_value':
        await (_db.update(
          _db.localItemFieldValues,
        )..where((t) => t.id.equals(entityId))).write(
          LocalItemFieldValuesCompanion(
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
      case 'service_order_item':
        await (_db.update(
          _db.localServiceOrderItems,
        )..where((t) => t.id.equals(entityId))).write(
          LocalServiceOrderItemsCompanion(
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
      case 'service_order_recommendation':
        await (_db.update(
          _db.localServiceOrderRecommendations,
        )..where((t) => t.id.equals(entityId))).write(
          LocalServiceOrderRecommendationsCompanion(
            version: Value(version),
            syncStatus: const Value('synced'),
            lastSyncedAt: Value(now),
            syncError: const Value(null),
          ),
        );
      case 'task':
        await (_db.update(
          _db.localTasks,
        )..where((t) => t.id.equals(entityId))).write(
          LocalTasksCompanion(
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
        await (_db.update(_db.localLocations)
              ..where((t) => t.id.equals(entityId)))
            .write(LocalLocationsCompanion(syncStatus: status, syncError: error));
      case 'item':
        await (_db.update(_db.localItems)..where((t) => t.id.equals(entityId)))
            .write(LocalItemsCompanion(syncStatus: status, syncError: error));
      case 'item_field_value':
        await (_db.update(
          _db.localItemFieldValues,
        )..where((t) => t.id.equals(entityId))).write(
          LocalItemFieldValuesCompanion(syncStatus: status, syncError: error),
        );
      case 'service_order':
        await (_db.update(
          _db.localServiceOrders,
        )..where((t) => t.id.equals(entityId))).write(
          LocalServiceOrdersCompanion(syncStatus: status, syncError: error),
        );
      case 'service_order_item':
        await (_db.update(
          _db.localServiceOrderItems,
        )..where((t) => t.id.equals(entityId))).write(
          LocalServiceOrderItemsCompanion(syncStatus: status, syncError: error),
        );
      case 'service_order_part':
        await (_db.update(
          _db.localServiceOrderParts,
        )..where((t) => t.id.equals(entityId))).write(
          LocalServiceOrderPartsCompanion(syncStatus: status, syncError: error),
        );
      case 'service_order_recommendation':
        await (_db.update(
          _db.localServiceOrderRecommendations,
        )..where((t) => t.id.equals(entityId))).write(
          LocalServiceOrderRecommendationsCompanion(
            syncStatus: status,
            syncError: error,
          ),
        );
      case 'task':
        await (_db.update(_db.localTasks)
              ..where((t) => t.id.equals(entityId)))
            .write(LocalTasksCompanion(syncStatus: status, syncError: error));
      case 'qr_code':
        await (_db.update(_db.localQrCodes)
              ..where((t) => t.id.equals(entityId)))
            .write(LocalQrCodesCompanion(syncStatus: status, syncError: error));
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
      case 'item':
        // `.toCompanion(false)` inclui `Value(null)` p/ colunas nulas — sem
        // isso o `insertOnConflictUpdate` não limpa `location_id` (desvínculo).
        await _db
            .into(_db.localItems)
            .insertOnConflictUpdate(
              itemFromApiJson(data, organizationId: org).toCompanion(false),
            );
      case 'item_field_value':
        await _db
            .into(_db.localItemFieldValues)
            .insertOnConflictUpdate(
              itemFieldValueFromApiJson(data, organizationId: org),
            );
      case 'service_order':
        await _db
            .into(_db.localServiceOrders)
            .insertOnConflictUpdate(
              serviceOrderFromApiJson(data, organizationId: org),
            );
      case 'service_order_item':
        await _db
            .into(_db.localServiceOrderItems)
            .insertOnConflictUpdate(
              serviceOrderItemFromApiJson(data, organizationId: org),
            );
      case 'service_order_part':
        await _db
            .into(_db.localServiceOrderParts)
            .insertOnConflictUpdate(
              servicePartFromApiJson(data, organizationId: org),
            );
      case 'service_order_recommendation':
        await _db
            .into(_db.localServiceOrderRecommendations)
            .insertOnConflictUpdate(
              serviceRecommendationFromApiJson(data, organizationId: org),
            );
      case 'task':
        // `.toCompanion(false)` preserva colunas nulas no upsert (senão o
        // `insertOnConflictUpdate` de data class as omite e não limpa).
        await _db
            .into(_db.localTasks)
            .insertOnConflictUpdate(
              taskFromApiJson(data, organizationId: org).toCompanion(false),
            );
        // Alvos derivam do payload da tarefa (não são entidade de sync).
        await (_db.delete(_db.localTaskTargets)
              ..where((t) => t.taskId.equals(data['id'] as String)))
            .go();
        for (final c in taskTargetsFromApiJson(data)) {
          await _db.into(_db.localTaskTargets).insert(c);
        }
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
      case 'item':
        await (_db.update(_db.localItems)..where((t) => t.id.equals(entityId)))
            .write(const LocalItemsCompanion(deleted: Value(true)));
      case 'item_field_value':
        await (_db.update(_db.localItemFieldValues)
              ..where((t) => t.id.equals(entityId)))
            .write(const LocalItemFieldValuesCompanion(deleted: Value(true)));
      case 'service_order':
        await (_db.update(_db.localServiceOrders)
              ..where((t) => t.id.equals(entityId)))
            .write(const LocalServiceOrdersCompanion(deleted: Value(true)));
      case 'service_order_item':
        await (_db.update(_db.localServiceOrderItems)
              ..where((t) => t.id.equals(entityId)))
            .write(const LocalServiceOrderItemsCompanion(deleted: Value(true)));
      case 'service_order_part':
        await (_db.update(_db.localServiceOrderParts)
              ..where((t) => t.id.equals(entityId)))
            .write(const LocalServiceOrderPartsCompanion(deleted: Value(true)));
      case 'task':
        await (_db.update(_db.localTasks)
              ..where((t) => t.id.equals(entityId)))
            .write(const LocalTasksCompanion(deleted: Value(true)));
        await (_db.delete(_db.localTaskTargets)
              ..where((t) => t.taskId.equals(entityId)))
            .go();
      case 'service_order_recommendation':
        await (_db.update(_db.localServiceOrderRecommendations)
              ..where((t) => t.id.equals(entityId)))
            .write(
              const LocalServiceOrderRecommendationsCompanion(
                deleted: Value(true),
              ),
            );
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
