import '../../../core/db/app_database.dart';

/// `GET /v1/item-types` → `{item_types: [ItemType]}` — dado de referência
/// REST-only (não sincroniza).
LocalItemType itemTypeFromApiJson(
  Map<String, dynamic> j, {
  required String organizationId,
}) => LocalItemType(
  id: j['id'] as String,
  organizationId: organizationId,
  name: (j['name'] as String?) ?? '',
  description: (j['description'] as String?) ?? '',
  version: j['version'] as int?,
  cachedAt: DateTime.now(),
);
