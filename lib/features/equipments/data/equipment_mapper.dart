import '../../../core/db/app_database.dart';
import '../../../core/network/api_parse.dart';

/// REST/sync ↔ `LocalEquipment`. `serial_number`/`cost` são mascaráveis
/// (nullable = sem permissão de leitura). `installed_at` fica como string
/// `YYYY-MM-DD`.
LocalEquipment equipmentFromApiJson(
  Map<String, dynamic> j, {
  required String organizationId,
}) {
  final now = DateTime.now();
  return LocalEquipment(
    id: j['id'] as String,
    organizationId: organizationId,
    locationId: stringOr(j['location_id']),
    equipmentTypeId: stringOr(j['equipment_type_id']),
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

Map<String, dynamic> equipmentUpdateBody({
  required String name,
  required String brand,
  required String model,
  required String notes,
}) => {'name': name, 'brand': brand, 'model': model, 'notes': notes};

/// `POST /v1/equipments` — só `location_id` e `name` obrigatórios; o tipo é
/// opcional (cadastro rápido a partir do seletor de itens da ordem).
Map<String, dynamic> equipmentCreateBody({
  required String locationId,
  String? equipmentTypeId,
  required String name,
  required String brand,
  required String model,
  required String notes,
}) => {
  'location_id': locationId,
  'equipment_type_id': ?(equipmentTypeId != null && equipmentTypeId.isNotEmpty
      ? equipmentTypeId
      : null),
  'name': name,
  'brand': brand,
  'model': model,
  'notes': notes,
};
