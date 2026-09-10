import '../../../core/db/app_database.dart';

/// `GET /v1/item-field-defs` → `{item_field_defs: [ItemFieldDef]}` — dado de
/// referência REST-only (não sincroniza). Cacheado pro form do item funcionar
/// offline.
LocalItemFieldDef itemFieldDefFromApiJson(
  Map<String, dynamic> j, {
  required String organizationId,
}) => LocalItemFieldDef(
  id: j['id'] as String,
  organizationId: organizationId,
  itemTypeId: j['item_type_id'] as String?,
  label: (j['label'] as String?) ?? '',
  fieldKey: (j['field_key'] as String?) ?? '',
  dataType: (j['data_type'] as String?) ?? 'text',
  required: (j['required'] as bool?) ?? false,
  position: (j['position'] as int?) ?? 0,
  version: j['version'] as int?,
  cachedAt: DateTime.now(),
);

List<LocalItemFieldOption> itemFieldOptionsFromApiJson(
  Map<String, dynamic> defJson, {
  required String organizationId,
}) {
  final raw = defJson['options'] as List? ?? const [];
  final defId = defJson['id'] as String;
  final now = DateTime.now();
  return [
    for (final o in raw)
      LocalItemFieldOption(
        id: (o as Map<String, dynamic>)['id'] as String,
        organizationId: organizationId,
        fieldDefId: defId,
        label: (o['label'] as String?) ?? '',
        value: (o['value'] as String?) ?? '',
        position: (o['position'] as int?) ?? 0,
        cachedAt: now,
      ),
  ];
}
