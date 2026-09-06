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

/// Espelha `Location` (spec §7.4) — endereço estruturado + hierarquia via
/// `parentLocationId` (auto-referência, só leitura nesta entrega: reparent é
/// REST-only, GUIA-FLUTTER.md §8.4).
class LocalLocations extends Table with _SyncColumns {
  TextColumn get id => text()();
  TextColumn get clientId => text().named('client_id')();
  TextColumn get parentLocationId =>
      text().named('parent_location_id').nullable()();
  TextColumn get name => text()();
  TextColumn get postalCode =>
      text().named('postal_code').withDefault(const Constant(''))();
  TextColumn get street => text().withDefault(const Constant(''))();
  TextColumn get number => text().withDefault(const Constant(''))();
  TextColumn get complement => text().withDefault(const Constant(''))();
  TextColumn get district => text().withDefault(const Constant(''))();
  TextColumn get city => text().withDefault(const Constant(''))();
  TextColumn get state => text().withDefault(const Constant(''))();
  TextColumn get contactPerson =>
      text().named('contact_person').withDefault(const Constant(''))();
  TextColumn get phone => text().withDefault(const Constant(''))();
  TextColumn get accessInstructions =>
      text().named('access_instructions').withDefault(const Constant(''))();
  TextColumn get notes => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().named('created_at').nullable()();
  DateTimeColumn get updatedAt => dateTime().named('updated_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Espelha `Equipment` (spec §7.5). `serialNumber`/`cost` são campos
/// sensíveis (mascaráveis) — nullable pelo mesmo motivo de
/// `internalNotes` em [LocalClients]. `installedAt` fica como texto
/// (`YYYY-MM-DD`, o formato que o servidor manda) — não precisamos de
/// aritmética de data nesta entrega, só exibir.
class LocalEquipments extends Table with _SyncColumns {
  TextColumn get id => text()();
  TextColumn get locationId => text().named('location_id')();
  TextColumn get equipmentTypeId => text().named('equipment_type_id')();
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

/// Espelha o cabeçalho de `ServiceOrder` (spec §7.6). `clientId` é imutável
/// depois de criada (só o `create` aceita, GUIA-FLUTTER.md §8.4);
/// `serviceOrderTypeId`/`companyId`/`assignedUserId`/`scheduledFor` ficam
/// fora desta entrega (dependem de entidades REST-only que o app ainda não
/// cacheia), mas as colunas já existem porque o servidor manda esses campos
/// no pull/bootstrap normalmente.
class LocalServiceOrders extends Table with _SyncColumns {
  TextColumn get id => text()();
  TextColumn get clientId => text().named('client_id')();
  TextColumn get locationId => text().named('location_id').nullable()();
  TextColumn get equipmentId => text().named('equipment_id').nullable()();
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
class LocalServiceOrderParts extends Table with _SyncColumns {
  TextColumn get id => text()();
  TextColumn get serviceOrderId => text().named('service_order_id')();
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

/// Tipos de equipamento (spec §7.5) — dado de referência **REST-only** (não
/// entra no protocolo de sync, GUIA-FLUTTER.md §8.4). Cacheado localmente só
/// para o seletor de "novo equipamento" funcionar offline; `cachedAt` marca
/// a última vez que veio do servidor.
class LocalEquipmentTypes extends Table {
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
  TextColumn get kind => text()(); // 'service_order_type' | 'company' | 'org_user'
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
/// `clientId`/`locationId`/`equipmentId` é preenchido quando `status` =
/// `assigned`.
class LocalQrCodes extends Table with _SyncColumns {
  TextColumn get id => text()();
  TextColumn get publicCode => text().named('public_code').nullable()();
  TextColumn get status => text()(); // available|reserved|issued|assigned|deactivated|replaced|lost
  TextColumn get batchId => text().named('batch_id').nullable()();
  TextColumn get clientId => text().named('client_id').nullable()();
  TextColumn get locationId => text().named('location_id').nullable()();
  TextColumn get equipmentId => text().named('equipment_id').nullable()();
  DateTimeColumn get assignedAt =>
      dateTime().named('assigned_at').nullable()();
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
  TextColumn get serviceOrderId => text().named('service_order_id')();
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
    LocalEquipments,
    LocalServiceOrders,
    LocalServiceOrderParts,
    LocalEquipmentTypes,
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
  int get schemaVersion => 6;

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
      if (from < 4) {
        await m.createTable(localEquipmentTypes);
      }
      if (from < 5) {
        await m.createTable(localReferenceData);
      }
      if (from < 6) {
        await m.createTable(localQrCodes);
        await m.createTable(localQrBatches);
      }
    },
  );
}
