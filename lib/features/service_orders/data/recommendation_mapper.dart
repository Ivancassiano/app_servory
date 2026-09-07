import '../../../core/db/app_database.dart';
import '../../../core/network/api_parse.dart';

/// REST/sync ↔ `LocalServiceOrderRecommendation`. Shape de
/// `GET /v1/service-orders/{id}/recommendations[].` == `data` do `sync/pull`
/// da entidade `service_order_recommendation`.

LocalServiceOrderRecommendation serviceRecommendationFromApiJson(
  Map<String, dynamic> j, {
  required String organizationId,
}) {
  final now = DateTime.now();
  return LocalServiceOrderRecommendation(
    id: j['id'] as String,
    organizationId: organizationId,
    serviceOrderId: stringOr(j['service_order_id']),
    serviceOrderItemId: j['service_order_item_id'] as String?,
    description: stringOr(j['description']),
    priority: stringOr(j['priority'], 'medium'),
    status: stringOr(j['status'], 'open'),
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

/// Corpo de `POST /v1/service-orders/{id}/recommendations` — **sem**
/// `service_order_id` (vem no path). O `payload` da fila de sync acrescenta
/// `service_order_id` (§8.4).
Map<String, dynamic> recommendationCreateBody({
  required String description,
  required String priority,
  required String status,
  required String notes,
  String? serviceOrderItemId,
}) => {
  'description': description,
  'priority': priority,
  'status': status,
  'notes': notes,
  'service_order_item_id': ?serviceOrderItemId,
};

Map<String, dynamic> recommendationUpdateBody({
  required String description,
  required String priority,
  required String status,
  required String notes,
}) => {
  'description': description,
  'priority': priority,
  'status': status,
  'notes': notes,
};
