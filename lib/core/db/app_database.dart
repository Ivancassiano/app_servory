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

/// Linha única por organização: cursor do último `pull` bem-sucedido.
class LocalSyncState extends Table {
  TextColumn get organizationId => text().named('organization_id')();
  IntColumn get cursor => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {organizationId};
}

@DriftDatabase(
  tables: [
    LocalClients,
    LocalLocations,
    LocalEquipments,
    SyncOutbox,
    LocalSyncState,
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
  int get schemaVersion => 1;
}
