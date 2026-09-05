import '../../../core/db/app_database.dart';

/// `GET /v1/equipment-types` → `{equipment_types: [EquipmentType]}` — dado
/// de referência REST-only (não sincroniza).
LocalEquipmentType equipmentTypeFromApiJson(
  Map<String, dynamic> j, {
  required String organizationId,
}) => LocalEquipmentType(
  id: j['id'] as String,
  organizationId: organizationId,
  name: (j['name'] as String?) ?? '',
  description: (j['description'] as String?) ?? '',
  version: j['version'] as int?,
  cachedAt: DateTime.now(),
);
