import '../../../core/db/app_database.dart';
import '../../../core/network/api_parse.dart';

/// REST/sync ↔ `LocalItem`. Item achatado: sem árvore, sem endereço/contato
/// próprios (agora vêm do Local via `location_id`). `serial_number`/`cost` são
/// mascaráveis (nulo = sem permissão de leitura).
LocalItem itemFromApiJson(
  Map<String, dynamic> j, {
  required String organizationId,
}) {
  final now = DateTime.now();
  return LocalItem(
    id: j['id'] as String,
    organizationId: organizationId,
    clientId: stringOr(j['client_id']),
    locationId: j['location_id'] as String?,
    itemTypeId: j['item_type_id'] as String?,
    name: stringOr(j['name']),
    brand: stringOr(j['brand']),
    model: stringOr(j['model']),
    serialNumber: maskable(j['serial_number']),
    internalLocation: stringOr(j['internal_location']),
    installedAt: j['installed_at'] as String?,
    cost: maskable(j['cost']),
    notes: stringOr(j['notes']),
    version: j['version'] as int?,
    createdAt: parseApiDate(j['created_at']),
    updatedAt: parseApiDate(j['updated_at']),
    localUpdatedAt: now,
    lastSyncedAt: now,
    syncStatus: 'synced',
    deleted: false,
  );
}

/// Campos comuns de `ItemInput` (create e update).
Map<String, dynamic> _itemFields({
  required String name,
  required String notes,
  String? itemTypeId,
  String? locationId,
}) => {
  'name': name,
  'notes': notes,
  // sempre presente (valor ou null): mandar null desvincula do local
  'location_id': locationId,
  'item_type_id': ?(itemTypeId != null && itemTypeId.isNotEmpty
      ? itemTypeId
      : null),
};

/// `POST /v1/items` — `client_id` e `name` obrigatórios.
Map<String, dynamic> itemCreateBody({
  required String clientId,
  String? itemTypeId,
  String? locationId,
  required String name,
  String notes = '',
}) => {
  'client_id': clientId,
  ..._itemFields(
    name: name,
    notes: notes,
    itemTypeId: itemTypeId,
    locationId: locationId,
  ),
};

/// `PATCH /v1/items/{id}`.
Map<String, dynamic> itemUpdateBody({
  String? itemTypeId,
  String? locationId,
  required String name,
  String notes = '',
}) => _itemFields(
  name: name,
  notes: notes,
  itemTypeId: itemTypeId,
  locationId: locationId,
);
