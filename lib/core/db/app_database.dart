import 'package:drift/drift.dart';

import 'connection/connection.dart';

part 'app_database.g.dart';

/// Colunas de sincronização presentes em toda tabela espelhando uma entidade
/// do servidor (GUIA-FLUTTER.md §5): `version` é o que o servidor confirmou
/// por último (nulo enquanto uma criação local ainda não sincronizou);
/// `syncStatus` reflete o estado local (`synced`/`pending`/`conflict`).
mixin _SyncColumns on Table {
  TextColumn get organizationId => text().named('organization_id')();
  IntColumn get version => integer().nullable()();
  TextColumn get syncStatus =>
      text().named('sync_status').withDefault(const Constant('synced'))();
  DateTimeColumn get localUpdatedAt => dateTime().named('local_updated_at')();
  DateTimeColumn get lastSyncedAt =>
      dateTime().named('last_synced_at').nullable()();
  TextColumn get syncError => text().named('sync_error').nullable()();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
}

/// Espelha o schema `Client` do OpenAPI (spec §7.3). Campos mascaráveis
/// (`internal_notes`) ficam nullable — ausência no JSON do servidor
/// significa "sem permissão de leitura" (GUIA-FLUTTER.md §4), distinto de
/// string vazia.
class LocalClients extends Table with _SyncColumns {
  TextColumn get id => text()();
  TextColumn get kind => text()();
  TextColumn get name => text()();
  TextColumn get legalName =>
      text().named('legal_name').withDefault(const Constant(''))();
  TextColumn get taxId =>
      text().named('tax_id').withDefault(const Constant(''))();
  TextColumn get phone => text().withDefault(const Constant(''))();
  TextColumn get email => text().withDefault(const Constant(''))();
  TextColumn get contactPerson =>
      text().named('contact_person').withDefault(const Constant(''))();
  TextColumn get internalNotes => text().named('internal_notes').nullable()();
  DateTimeColumn get createdAt => dateTime().named('created_at').nullable()();
  DateTimeColumn get updatedAt => dateTime().named('updated_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Espelha `Item` do OpenAPI — a fusão de local + equipamento (spec §7.4/§7.5
/// reescritos). Árvore livre via `parentItemId` (reparent é REST-only:
/// PATCH /v1/items/{id}/parent). Endereço estruturado opcional (herda do
/// ancestral). `serialNumber`/`cost` são campos sensíveis (mascaráveis) —
/// nullable pelo mesmo motivo de `internalNotes` em [LocalClients]:
/// ausência no JSON do servidor é "sem permissão de leitura", não vazio.
class LocalItems extends Table with _SyncColumns {
  TextColumn get id => text()();
  TextColumn get clientId => text().named('client_id')();
  TextColumn get locationId => text().named('location_id').nullable()();
  TextColumn get itemTypeId => text().named('item_type_id').nullable()();
  TextColumn get name => text()();
  TextColumn get brand => text().withDefault(const Constant(''))();
  TextColumn get model => text().withDefault(const Constant(''))();
  TextColumn get serialNumber => text().named('serial_number').nullable()();
  TextColumn get internalLocation =>
      text().named('internal_location').withDefault(const Constant(''))();
  TextColumn get installedAt => text().named('installed_at').nullable()();
  TextColumn get cost => text().nullable()();
  TextColumn get notes => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().named('created_at').nullable()();
  DateTimeColumn get updatedAt => dateTime().named('updated_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Espelha `Location` do OpenAPI — endereço estruturado + rótulo curto de um
/// cliente. Um item aponta para no máximo um local (`LocalItems.locationId`).
/// Sincroniza.
class LocalLocations extends Table with _SyncColumns {
  TextColumn get id => text()();
  TextColumn get clientId => text().named('client_id')();
  TextColumn get name => text().withDefault(const Constant(''))();
  TextColumn get postalCode =>
      text().named('postal_code').withDefault(const Constant(''))();
  TextColumn get street => text().withDefault(const Constant(''))();
  TextColumn get number => text().withDefault(const Constant(''))();
  TextColumn get complement => text().withDefault(const Constant(''))();
  TextColumn get district => text().withDefault(const Constant(''))();
  TextColumn get city => text().withDefault(const Constant(''))();
  TextColumn get state => text().withDefault(const Constant(''))();
  TextColumn get notes => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().named('created_at').nullable()();
  DateTimeColumn get updatedAt => dateTime().named('updated_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Definição de campo personalizado de item (`ItemFieldDef` do OpenAPI) —
/// dado de referência **REST-only** (não entra no sync). `itemTypeId` nulo =
/// campo global; preenchido = só daquele tipo. Cacheado pro form do item
/// funcionar offline.
class LocalItemFieldDefs extends Table {
  TextColumn get id => text()();
  TextColumn get organizationId => text().named('organization_id')();
  TextColumn get itemTypeId => text().named('item_type_id').nullable()();
  TextColumn get label => text()();
  TextColumn get fieldKey => text().named('field_key')();
  TextColumn get dataType => text().named('data_type')();
  BoolColumn get required => boolean().withDefault(const Constant(false))();
  IntColumn get position => integer().withDefault(const Constant(0))();
  IntColumn get version => integer().nullable()();
  DateTimeColumn get cachedAt => dateTime().named('cached_at')();

  @override
  Set<Column> get primaryKey => {id};
}

/// Opções de um campo `select` (`ItemFieldDef.options`) — cacheado junto com
/// os defs, REST-only.
class LocalItemFieldOptions extends Table {
  TextColumn get id => text()();
  TextColumn get organizationId => text().named('organization_id')();
  TextColumn get fieldDefId => text().named('field_def_id')();
  TextColumn get label => text()();
  TextColumn get value => text()();
  IntColumn get position => integer().withDefault(const Constant(0))();
  DateTimeColumn get cachedAt => dateTime().named('cached_at')();

  @override
  Set<Column> get primaryKey => {id};
}

/// Valor de um campo personalizado para um item (`ItemFieldValue` do OpenAPI)
/// — EAV com colunas tipadas, **sincroniza** (o técnico preenche no cadastro,
/// offline). Só uma das 4 colunas de valor fica preenchida, conforme o
/// `dataType` do def.
class LocalItemFieldValues extends Table with _SyncColumns {
  TextColumn get id => text()();
  TextColumn get itemId => text().named('item_id')();
  TextColumn get fieldDefId => text().named('field_def_id')();
  TextColumn get valueText => text().named('value_text').nullable()();
  RealColumn get valueNumber => real().named('value_number').nullable()();
  DateTimeColumn get valueDatetime =>
      dateTime().named('value_datetime').nullable()();
  BoolColumn get valueBoolean => boolean().named('value_boolean').nullable()();
  DateTimeColumn get createdAt => dateTime().named('created_at').nullable()();
  DateTimeColumn get updatedAt => dateTime().named('updated_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Espelha o cabeçalho de `ServiceOrder` (spec §7.6). `clientId` é imutável
/// depois de criada (só o `create` aceita, GUIA-FLUTTER.md §8.4);
/// `serviceOrderTypeId`/`companyId`/`assignedUserId`/`scheduledFor` ficam
/// fora desta entrega (dependem de entidades REST-only que o app ainda não
/// cacheia), mas as colunas já existem porque o servidor manda esses campos
/// no pull/bootstrap normalmente.
class LocalServiceOrders extends Table with _SyncColumns {
  TextColumn get id => text()();
  TextColumn get clientId => text().named('client_id')();
  TextColumn get itemId => text().named('item_id').nullable()();
  TextColumn get parentOrderId => text().named('parent_order_id').nullable()();
  TextColumn get serviceOrderTypeId =>
      text().named('service_order_type_id').nullable()();
  TextColumn get companyId => text().named('company_id').nullable()();
  TextColumn get assignedUserId =>
      text().named('assigned_user_id').nullable()();
  TextColumn get status => text().withDefault(const Constant('draft'))();
  TextColumn get reason => text().withDefault(const Constant(''))();
  TextColumn get diagnosis => text().withDefault(const Constant(''))();
  TextColumn get workPerformed =>
      text().named('work_performed').withDefault(const Constant(''))();
  TextColumn get recommendations => text().withDefault(const Constant(''))();
  TextColumn get finalCondition =>
      text().named('final_condition').withDefault(const Constant(''))();
  TextColumn get notes => text().withDefault(const Constant(''))();
  DateTimeColumn get scheduledFor =>
      dateTime().named('scheduled_for').nullable()();
  DateTimeColumn get startedAt => dateTime().named('started_at').nullable()();
  DateTimeColumn get completedAt =>
      dateTime().named('completed_at').nullable()();
  DateTimeColumn get createdAt => dateTime().named('created_at').nullable()();
  DateTimeColumn get updatedAt => dateTime().named('updated_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Peças/materiais de uma ordem (spec §7.6 "Peças e materiais"). `unitCost`/
/// `unitPrice` são sensíveis (grupo de campo `cost`) — nullable pelo mesmo
/// motivo de `serialNumber`/`cost` em [LocalEquipments]: ausência no JSON do
/// servidor é "sem permissão de leitura", não vazio.
/// Itens (laudo por equipamento) de uma ordem — espelha `ServiceOrderItem` do
/// OpenAPI. Opcional: uma ordem pode não ter item e usar só o laudo geral.
class LocalServiceOrderItems extends Table with _SyncColumns {
  TextColumn get id => text()();
  TextColumn get serviceOrderId => text().named('service_order_id')();
  TextColumn get itemId => text().named('item_id')();
  IntColumn get position => integer().withDefault(const Constant(0))();
  TextColumn get diagnosis => text().withDefault(const Constant(''))();
  TextColumn get workPerformed =>
      text().named('work_performed').withDefault(const Constant(''))();
  TextColumn get finalCondition =>
      text().named('final_condition').withDefault(const Constant(''))();
  TextColumn get note => text().withDefault(const Constant(''))();
  TextColumn get approval => text().withDefault(const Constant('pending'))();
  DateTimeColumn get approvedAt => dateTime().named('approved_at').nullable()();
  DateTimeColumn get createdAt => dateTime().named('created_at').nullable()();
  DateTimeColumn get updatedAt => dateTime().named('updated_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalServiceOrderParts extends Table with _SyncColumns {
  TextColumn get id => text()();
  TextColumn get serviceOrderId => text().named('service_order_id')();
  TextColumn get serviceOrderItemId =>
      text().named('service_order_item_id').nullable()();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get partNumber =>
      text().named('part_number').withDefault(const Constant(''))();
  TextColumn get quantity => text().withDefault(const Constant('1'))();
  TextColumn get unit => text().withDefault(const Constant(''))();
  TextColumn get unitCost => text().named('unit_cost').nullable()();
  TextColumn get unitPrice => text().named('unit_price').nullable()();
  TextColumn get notes => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().named('created_at').nullable()();
  DateTimeColumn get updatedAt => dateTime().named('updated_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Recomendações "para a próxima visita" (spec §7.6). Sincroniza como as peças
/// (entidade `service_order_recommendation`); `serviceOrderItemId` liga a
/// recomendação a um item da visita (`null` = recomendação geral da ordem).
class LocalServiceOrderRecommendations extends Table with _SyncColumns {
  TextColumn get id => text()();
  TextColumn get serviceOrderId => text().named('service_order_id')();
  TextColumn get serviceOrderItemId =>
      text().named('service_order_item_id').nullable()();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get priority => text().withDefault(const Constant('medium'))();
  TextColumn get status => text().withDefault(const Constant('open'))();
  TextColumn get notes => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().named('created_at').nullable()();
  DateTimeColumn get updatedAt => dateTime().named('updated_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Espelha `Task` do OpenAPI — a camada de planejamento antes da ordem
/// (spec: tarefa). UM cliente; alvos (locais/itens) ficam em
/// [LocalTaskTargets], derivada do payload da tarefa no pull (não é entidade
/// de sync própria). Sincroniza (`entity_type` = `task`); ações
/// complete/cancel/reopen são operações nomeadas na outbox.
class LocalTasks extends Table with _SyncColumns {
  TextColumn get id => text()();
  TextColumn get clientId => text().named('client_id')();
  TextColumn get taskTypeId => text().named('task_type_id').nullable()();
  TextColumn get assignedUserId =>
      text().named('assigned_user_id').nullable()();
  TextColumn get companyId => text().named('company_id').nullable()();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get notes => text().withDefault(const Constant(''))();
  TextColumn get status => text().withDefault(const Constant('open'))();
  DateTimeColumn get scheduledFor =>
      dateTime().named('scheduled_for').nullable()();
  BoolColumn get scheduledAllDay =>
      boolean().named('scheduled_all_day').withDefault(const Constant(false))();
  TextColumn get recurrenceRule =>
      text().named('recurrence_rule').withDefault(const Constant(''))();
  TextColumn get generatedOrderId =>
      text().named('generated_order_id').nullable()();
  DateTimeColumn get completedAt =>
      dateTime().named('completed_at').nullable()();
  DateTimeColumn get canceledAt => dateTime().named('canceled_at').nullable()();
  DateTimeColumn get createdAt => dateTime().named('created_at').nullable()();
  DateTimeColumn get updatedAt => dateTime().named('updated_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Alvos de uma tarefa (local, item, ou item dentro de um local). Tabela
/// **plana** — não sincroniza sozinha: o `sync_engine` a reescreve inteira a
/// partir de `data['targets']` do payload da tarefa (pull) e o repositório a
/// reescreve no create/update local.
class LocalTaskTargets extends Table {
  TextColumn get id => text()();
  TextColumn get taskId => text().named('task_id')();
  TextColumn get locationId => text().named('location_id').nullable()();
  TextColumn get itemId => text().named('item_id').nullable()();
  IntColumn get position => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Outbox local (GUIA-FLUTTER.md §8.1): uma linha por operação pendente de
/// envio. `payload` é o corpo JSON (mesmo shape do POST/PATCH REST
/// equivalente) serializado como texto.
class SyncOutbox extends Table {
  TextColumn get operationId => text().named('operation_id')();
  TextColumn get organizationId => text().named('organization_id')();
  TextColumn get entityType => text().named('entity_type')();
  TextColumn get entityId => text().named('entity_id')();
  TextColumn get operationType => text().named('operation_type')();
  TextColumn get payload => text()();
  IntColumn get baseVersion => integer().named('base_version').nullable()();
  DateTimeColumn get occurredAt => dateTime().named('occurred_at')();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().named('last_error').nullable()();

  @override
  Set<Column> get primaryKey => {operationId};
}

/// Tipos de item (spec §6) — dado de referência **REST-only** (não entra no
/// protocolo de sync, GUIA-FLUTTER.md §8.4). Cacheado localmente só para o
/// seletor de "novo item" funcionar offline; `cachedAt` marca a última vez
/// que veio do servidor.
class LocalItemTypes extends Table {
  TextColumn get id => text()();
  TextColumn get organizationId => text().named('organization_id')();
  TextColumn get name => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  IntColumn get version => integer().nullable()();
  DateTimeColumn get cachedAt => dateTime().named('cached_at')();

  @override
  Set<Column> get primaryKey => {id};
}

/// Dados de referência **REST-only** que não entram no protocolo de sync
/// (GUIA-FLUTTER.md §8.4): tipos de ordem de serviço, empresas emitentes e
/// membros da organização. Guardados numa tabela única, chaveada por `kind`,
/// só para os seletores do formulário de ordem funcionarem offline (precisa
/// ter ficado online ao menos uma vez). `label` é o texto exibido; `subtitle`
/// é o complemento (ex.: e-mail do usuário). `cachedAt` marca a última busca.
class LocalReferenceData extends Table {
  TextColumn get kind =>
      text()(); // 'service_order_type' | 'company' | 'org_user'
  TextColumn get id => text()();
  TextColumn get organizationId => text().named('organization_id')();
  TextColumn get label => text()();
  TextColumn get subtitle => text().withDefault(const Constant(''))();
  DateTimeColumn get cachedAt => dateTime().named('cached_at')();

  @override
  Set<Column> get primaryKey => {kind, id};
}

/// Espelha `QRCode` do OpenAPI (spec §8-§9). Etiqueta sincronizável
/// (`create`/`assign`/`replace`/`deactivate`, GUIA-FLUTTER.md §8.4). **Não
/// usa `version` de verdade** — a regra de conflito é "primeira confirmação
/// do servidor vence" (§9.3); ainda assim carregamos `version` porque o
/// protocolo de push exige `base_version` como forma. `publicCode` é o texto
/// impresso/escaneável — só o servidor gera (ADR-0019), fica nulo enquanto
/// uma etiqueta criada offline não sincronizou. Exatamente um entre
/// `clientId`/`itemId` é preenchido quando `status` = `assigned`.
class LocalQrCodes extends Table with _SyncColumns {
  TextColumn get id => text()();
  TextColumn get publicCode => text().named('public_code').nullable()();
  TextColumn get status =>
      text()(); // available|reserved|issued|assigned|deactivated|replaced|lost
  TextColumn get batchId => text().named('batch_id').nullable()();
  TextColumn get clientId => text().named('client_id').nullable()();
  TextColumn get itemId => text().named('item_id').nullable()();
  DateTimeColumn get assignedAt => dateTime().named('assigned_at').nullable()();
  DateTimeColumn get createdAt => dateTime().named('created_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Espelha `QRBatch` do OpenAPI. **Somente leitura** no app (aparece em
/// `pull`/`bootstrap`; criar/reservar/exportar lote é sempre REST,
/// GUIA-FLUTTER.md §8.4). Usa `version` normalmente.
@DataClassName('LocalQrBatch')
class LocalQrBatches extends Table with _SyncColumns {
  TextColumn get id => text()();
  TextColumn get label => text().withDefault(const Constant(''))();
  IntColumn get quantity => integer().withDefault(const Constant(0))();
  TextColumn get status => text()(); // created|reserved|issued|lost
  TextColumn get reservedUserId =>
      text().named('reserved_user_id').nullable()();
  TextColumn get reservedDeviceId =>
      text().named('reserved_device_id').nullable()();
  IntColumn get exportCount =>
      integer().named('export_count').withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().named('created_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Linha única por organização: cursor do último `pull` bem-sucedido.
class LocalSyncState extends Table {
  TextColumn get organizationId => text().named('organization_id')();
  IntColumn get cursor => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {organizationId};
}

/// Fila de upload de anexo (foto/assinatura, GUIA-FLUTTER.md §7) — fotos e
/// assinatura não fazem parte do protocolo de sync (upload é
/// `multipart/form-data`, não JSON via `/v1/sync/push`), então esta fila é
/// separada da [SyncOutbox]: não tem `operation_type`, é sempre "enviar
/// este arquivo". `filePath` aponta pro arquivo já salvo localmente (a
/// captura funciona sempre, mesmo offline); sucesso no envio remove a linha
/// mas nunca apaga o arquivo (a fatia de PDF local vai precisar dele).
class UploadQueue extends Table {
  TextColumn get id => text()();
  TextColumn get organizationId => text().named('organization_id')();
  // Dono do anexo: 'service_order' | 'item' | 'location'. Para OS,
  // ownerId == serviceOrderId.
  TextColumn get ownerKind => text()
      .named('owner_kind')
      .withDefault(const Constant('service_order'))();
  TextColumn get ownerId => text().named('owner_id')();
  TextColumn get serviceOrderId =>
      text().named('service_order_id').nullable()();
  TextColumn get serviceOrderItemId =>
      text().named('service_order_item_id').nullable()();
  TextColumn get kind => text()(); // 'photo' | 'signature'
  TextColumn get filePath => text().named('file_path')();
  TextColumn get sha256 => text()();
  TextColumn get photoKind => text().named('photo_kind').nullable()();
  TextColumn get caption => text().nullable()();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().named('last_error').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    LocalClients,
    LocalLocations,
    LocalItems,
    LocalItemTypes,
    LocalItemFieldDefs,
    LocalItemFieldOptions,
    LocalItemFieldValues,
    LocalServiceOrders,
    LocalServiceOrderItems,
    LocalServiceOrderParts,
    LocalServiceOrderRecommendations,
    LocalTasks,
    LocalTaskTargets,
    LocalReferenceData,
    LocalQrCodes,
    LocalQrBatches,
    SyncOutbox,
    LocalSyncState,
    UploadQueue,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// Abre (ou cria) o banco criptografado desta organização (spec §18.2).
  factory AppDatabase.forOrganization(String organizationId) {
    return AppDatabase(connectToOrganizationDatabase(organizationId));
  }

  /// Só para testes: banco em memória, sem criptografia nem plataforma.
  factory AppDatabase.forTesting(QueryExecutor executor) =>
      AppDatabase(executor);

  @override
  int get schemaVersion => 14;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(localServiceOrders);
        await m.createTable(localServiceOrderParts);
      }
      if (from < 3) {
        await m.createTable(uploadQueue);
      }
      if (from < 5) {
        await m.createTable(localReferenceData);
      }
      if (from < 6) {
        await m.createTable(localQrCodes);
        await m.createTable(localQrBatches);
      }
      if (from < 7) {
        await m.createTable(localServiceOrderItems);
        await m.addColumn(
          localServiceOrderParts,
          localServiceOrderParts.serviceOrderItemId,
        );
      }
      if (from < 8) {
        // Fusão local+equipamento → item (backend limpou a base): derruba as
        // tabelas afetadas, recria no schema novo e zera o cursor de sync
        // para um bootstrap completo. Writes offline pendentes de
        // local/equipamento são descartados.
        for (final t in const [
          'local_locations',
          'local_equipments',
          'local_equipment_types',
          'local_service_orders',
          'local_service_order_items',
          'local_service_order_parts',
          'local_qr_codes',
        ]) {
          await m.database.customStatement('DROP TABLE IF EXISTS $t');
        }
        await m.createTable(localItems);
        await m.createTable(localItemTypes);
        await m.createTable(localItemFieldDefs);
        await m.createTable(localItemFieldOptions);
        await m.createTable(localItemFieldValues);
        await m.createTable(localServiceOrders);
        await m.createTable(localServiceOrderItems);
        await m.createTable(localServiceOrderParts);
        await m.createTable(localQrCodes);
        await m.database.customStatement('DELETE FROM local_sync_state');
        await m.database.customStatement('DELETE FROM sync_outbox');
      }
      if (from >= 8 && from < 9) {
        // parent_order_id só é novo para quem já estava em v8 (a recriação do
        // bloco from<8 já traz a coluna).
        await m.addColumn(localServiceOrders, localServiceOrders.parentOrderId);
      }
      if (from < 10) {
        // Recomendações passam a sincronizar (antes eram REST-only, sem tabela
        // local). Cria a tabela e zera o cursor para o bootstrap trazê-las
        // (quem vinha de < 8 já reiniciou o cursor no bloco acima).
        await m.database.customStatement(
          'DROP TABLE IF EXISTS local_service_order_recommendations',
        );
        await m.createTable(localServiceOrderRecommendations);
        await m.database.customStatement('DELETE FROM local_sync_state');
      }
      if (from < 11) {
        // Fotos passam a poder ser vinculadas a um item da visita. A fila de
        // upload é local (não sincroniza) — só um ALTER, sem bootstrap.
        await m.addColumn(uploadQueue, uploadQueue.serviceOrderItemId);
      }
      if (from < 12) {
        // Nova entidade Local; item achatado (some árvore + endereço + contato,
        // entra location_id); fila de upload generalizada (owner_kind/owner_id).
        for (final t in const [
          'local_items',
          'local_locations',
          'upload_queue',
        ]) {
          await m.database.customStatement('DROP TABLE IF EXISTS $t');
        }
        await m.createTable(localItems);
        await m.createTable(localLocations);
        await m.createTable(uploadQueue);
      }
      if (from < 13) {
        // O backend TRUNCOU o outbox na migração dos Locais → um `pull` não
        // traz nada de volta; a única forma de repovoar é um bootstrap
        // completo, que só dispara se `local_clients` estiver vazio
        // (bootstrapIfNeeded). Então limpa TODAS as tabelas que sincronizam.
        for (final t in const [
          'local_clients',
          'local_locations',
          'local_items',
          'local_item_field_values',
          'local_service_orders',
          'local_service_order_items',
          'local_service_order_parts',
          'local_service_order_recommendations',
          'local_qr_codes',
          'local_qr_batches',
          'local_sync_state',
          'sync_outbox',
        ]) {
          await m.database.customStatement('DELETE FROM $t');
        }
      }
      if (from < 14) {
        // Nova entidade Tarefa. Não há tarefa histórica: o primeiro `pull`
        // após o upgrade traz tudo com cursor 0 para a entidade nova, sem
        // precisar de bootstrap. Só cria as duas tabelas.
        await m.createTable(localTasks);
        await m.createTable(localTaskTargets);
      }
    },
  );
}
