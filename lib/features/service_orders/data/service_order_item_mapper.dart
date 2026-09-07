import '../../../core/db/app_database.dart';
import '../../../core/network/api_parse.dart';

/// REST/sync ↔ `LocalServiceOrderItem`. Shape de `ServiceOrderItem` do OpenAPI
/// (== `data` do `sync/pull`).
LocalServiceOrderItem serviceOrderItemFromApiJson(
  Map<String, dynamic> j, {
  required String organizationId,
}) {
  final now = DateTime.now();
  return LocalServiceOrderItem(
    id: j['id'] as String,
    organizationId: organizationId,
    serviceOrderId: stringOr(j['service_order_id']),
    locationId: stringOr(j['location_id']),
    equipmentId: j['equipment_id'] as String?,
    position: (j['position'] as num?)?.toInt() ?? 0,
    diagnosis: stringOr(j['diagnosis']),
    workPerformed: stringOr(j['work_performed']),
    finalCondition: stringOr(j['final_condition']),
    note: stringOr(j['note']),
    approval: stringOr(j['approval'], 'pending'),
    approvedAt: parseApiDate(j['approved_at']),
    version: j['version'] as int?,
    createdAt: parseApiDate(j['created_at']),
    updatedAt: parseApiDate(j['updated_at']),
    localUpdatedAt: now,
    lastSyncedAt: now,
    syncStatus: 'synced',
    deleted: false,
  );
}

/// Corpo de `POST/PATCH /v1/service-orders/{id}/items` — **sem**
/// `service_order_id` (vem no path). O `payload` da fila de sync acrescenta
/// `service_order_id` (§8.4).
Map<String, dynamic> serviceOrderItemBody({
  String? locationId,
  String? equipmentId,
  int? position,
  required String diagnosis,
  required String workPerformed,
  required String finalCondition,
  required String note,
}) => {
  'location_id': ?locationId,
  'equipment_id': ?equipmentId,
  'position': ?position,
  'diagnosis': diagnosis,
  'work_performed': workPerformed,
  'final_condition': finalCondition,
  'note': note,
};
