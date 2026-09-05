import '../../../core/db/app_database.dart';
import '../../../core/network/api_parse.dart';

/// REST/sync ↔ `LocalServiceOrder` / `LocalServiceOrderPart`. Shape de
/// `GET /v1/service-orders/{id}` == `data` do `sync/pull`.

LocalServiceOrder serviceOrderFromApiJson(
  Map<String, dynamic> j, {
  required String organizationId,
}) {
  final now = DateTime.now();
  return LocalServiceOrder(
    id: j['id'] as String,
    organizationId: organizationId,
    clientId: stringOr(j['client_id']),
    locationId: j['location_id'] as String?,
    equipmentId: j['equipment_id'] as String?,
    serviceOrderTypeId: j['service_order_type_id'] as String?,
    companyId: j['company_id'] as String?,
    assignedUserId: j['assigned_user_id'] as String?,
    status: stringOr(j['status'], 'draft'),
    reason: stringOr(j['reason']),
    diagnosis: stringOr(j['diagnosis']),
    workPerformed: stringOr(j['work_performed']),
    recommendations: stringOr(j['recommendations']),
    finalCondition: stringOr(j['final_condition']),
    notes: stringOr(j['notes']),
    scheduledFor: parseApiDate(j['scheduled_for']),
    startedAt: parseApiDate(j['started_at']),
    completedAt: parseApiDate(j['completed_at']),
    version: j['version'] as int?,
    createdAt: parseApiDate(j['created_at']),
    updatedAt: parseApiDate(j['updated_at']),
    localUpdatedAt: now,
    lastSyncedAt: now,
    syncStatus: 'synced',
    deleted: false,
  );
}

LocalServiceOrderPart servicePartFromApiJson(
  Map<String, dynamic> j, {
  required String organizationId,
}) {
  final now = DateTime.now();
  return LocalServiceOrderPart(
    id: j['id'] as String,
    organizationId: organizationId,
    serviceOrderId: stringOr(j['service_order_id']),
    description: stringOr(j['description']),
    partNumber: stringOr(j['part_number']),
    quantity: j['quantity']?.toString() ?? '1',
    unit: stringOr(j['unit']),
    unitCost: j['unit_cost']?.toString(),
    unitPrice: j['unit_price']?.toString(),
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

// --- corpos de escrita ------------------------------------------------------

Map<String, dynamic> serviceOrderCreateBody({
  required String clientId,
  String? locationId,
  String? equipmentId,
  required bool open,
  required String reason,
}) => {
  'client_id': clientId,
  'location_id': ?locationId,
  'equipment_id': ?equipmentId,
  'open': open,
  'reason': reason,
};

Map<String, dynamic> serviceOrderUpdateBody({
  String? locationId,
  String? equipmentId,
  required String reason,
  required String diagnosis,
  required String workPerformed,
  required String finalCondition,
  required String notes,
}) => {
  'location_id': ?locationId,
  'equipment_id': ?equipmentId,
  'reason': reason,
  'diagnosis': diagnosis,
  'work_performed': workPerformed,
  'final_condition': finalCondition,
  'notes': notes,
};

String _q(String quantity) => quantity.isEmpty ? '1' : quantity;

/// O backend aceita ponto decimal — normaliza a vírgula do formato BR.
String? _money(String v) =>
    v.trim().isEmpty ? null : v.trim().replaceAll(',', '.');

/// Corpo de `POST /v1/service-orders/{id}/parts` — **sem** `service_order_id`
/// (vem no path; o backend rejeita campo desconhecido). O `payload` da fila
/// de sync acrescenta `service_order_id` à parte (§8.4).
Map<String, dynamic> servicePartCreateBody({
  required String description,
  required String partNumber,
  required String quantity,
  required String unit,
  required String unitCost,
  required String unitPrice,
  required String notes,
}) => {
  'description': description,
  'part_number': partNumber,
  'quantity': _q(quantity),
  'unit': unit,
  'unit_cost': _money(unitCost),
  'unit_price': _money(unitPrice),
  'notes': notes,
};

Map<String, dynamic> servicePartUpdateBody({
  required String description,
  required String partNumber,
  required String quantity,
  required String unit,
  required String unitCost,
  required String unitPrice,
  required String notes,
}) => {
  'description': description,
  'part_number': partNumber,
  'quantity': _q(quantity),
  'unit': unit,
  'unit_cost': _money(unitCost),
  'unit_price': _money(unitPrice),
  'notes': notes,
};
