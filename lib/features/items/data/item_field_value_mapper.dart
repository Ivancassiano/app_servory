import '../../../core/db/app_database.dart';

/// REST/sync ↔ `LocalItemFieldValue`. As 4 colunas de valor vêm cruas; só uma
/// fica preenchida conforme o `data_type` do def.
LocalItemFieldValue itemFieldValueFromApiJson(
  Map<String, dynamic> j, {
  required String organizationId,
}) {
  final now = DateTime.now();
  return LocalItemFieldValue(
    id: j['id'] as String,
    organizationId: organizationId,
    itemId: j['item_id'] as String,
    fieldDefId: j['field_def_id'] as String,
    valueText: j['value_text'] as String?,
    valueNumber: (j['value_number'] as num?)?.toDouble(),
    valueDatetime: j['value_datetime'] == null
        ? null
        : DateTime.tryParse(j['value_datetime'].toString()),
    valueBoolean: j['value_boolean'] as bool?,
    version: j['version'] as int?,
    createdAt: DateTime.tryParse('${j['created_at']}'),
    updatedAt: DateTime.tryParse('${j['updated_at']}'),
    localUpdatedAt: now,
    lastSyncedAt: now,
    syncStatus: 'synced',
    deleted: false,
  );
}
