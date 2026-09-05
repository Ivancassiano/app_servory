import '../../../core/db/app_database.dart';
import '../../../core/network/api_parse.dart';

/// REST/sync ↔ `LocalLocation`. A resposta (`GET` e `data` de sync) traz o
/// endereço **plano** (`postal_code`, `street`, …); só o corpo de
/// `POST/PATCH` aninha sob `address` — tratado nos `*Body` da Fatia 2.
LocalLocation locationFromApiJson(
  Map<String, dynamic> j, {
  required String organizationId,
}) {
  final now = DateTime.now();
  return LocalLocation(
    id: j['id'] as String,
    organizationId: organizationId,
    clientId: stringOr(j['client_id']),
    parentLocationId: j['parent_location_id'] as String?,
    name: stringOr(j['name']),
    postalCode: stringOr(j['postal_code']),
    street: stringOr(j['street']),
    number: stringOr(j['number']),
    complement: stringOr(j['complement']),
    district: stringOr(j['district']),
    city: stringOr(j['city']),
    state: stringOr(j['state']),
    contactPerson: stringOr(j['contact_person']),
    phone: stringOr(j['phone']),
    accessInstructions: stringOr(j['access_instructions']),
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

/// Campos de topo do `LocationInput` (endereço estruturado fica pra depois).
Map<String, dynamic> locationUpdateBody({
  required String name,
  required String contactPerson,
  required String phone,
  required String notes,
}) => {
  'name': name,
  'contact_person': contactPerson,
  'phone': phone,
  'notes': notes,
};

/// `POST /v1/locations` — `client_id` e `name` obrigatórios; `parent_location_id`
/// opcional (hierarquia).
Map<String, dynamic> locationCreateBody({
  required String clientId,
  String? parentLocationId,
  required String name,
  required String contactPerson,
  required String phone,
  required String notes,
}) => {
  'client_id': clientId,
  'parent_location_id': ?parentLocationId,
  'name': name,
  'contact_person': contactPerson,
  'phone': phone,
  'notes': notes,
};
