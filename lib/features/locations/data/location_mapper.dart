import '../../../core/db/app_database.dart';
import '../../../core/network/api_parse.dart';

/// REST/sync ↔ `LocalLocation`. A resposta (`GET` e `data` de sync) traz o
/// endereço **plano** (`postal_code`, `street`, …); só o corpo de `POST/PATCH`
/// aninha sob `address`.
LocalLocation locationFromApiJson(
  Map<String, dynamic> j, {
  required String organizationId,
}) {
  final now = DateTime.now();
  return LocalLocation(
    id: j['id'] as String,
    organizationId: organizationId,
    clientId: stringOr(j['client_id']),
    name: stringOr(j['name']),
    postalCode: stringOr(j['postal_code']),
    street: stringOr(j['street']),
    number: stringOr(j['number']),
    complement: stringOr(j['complement']),
    district: stringOr(j['district']),
    city: stringOr(j['city']),
    state: stringOr(j['state']),
    notes: stringOr(j['notes']),
    isActive: j['is_active'] as bool? ?? true,
    version: j['version'] as int?,
    createdAt: parseApiDate(j['created_at']),
    updatedAt: parseApiDate(j['updated_at']),
    localUpdatedAt: now,
    lastSyncedAt: now,
    syncStatus: 'synced',
    deleted: false,
  );
}

/// Endereço estruturado do local — aninha em `address` no POST/PATCH e no
/// payload de sync; a resposta devolve plano.
class LocationAddressInput {
  const LocationAddressInput({
    this.postalCode = '',
    this.street = '',
    this.number = '',
    this.complement = '',
    this.district = '',
    this.city = '',
    this.state = '',
  });

  final String postalCode;
  final String street;
  final String number;
  final String complement;
  final String district;
  final String city;
  final String state;

  static const empty = LocationAddressInput();

  factory LocationAddressInput.of(LocalLocation l) => LocationAddressInput(
    postalCode: l.postalCode,
    street: l.street,
    number: l.number,
    complement: l.complement,
    district: l.district,
    city: l.city,
    state: l.state,
  );

  Map<String, dynamic> toJson() => {
    'postal_code': postalCode,
    'street': street,
    'number': number,
    'complement': complement,
    'district': district,
    'city': city,
    'state': state,
  };
}

Map<String, dynamic> _locationFields({
  required String name,
  required String notes,
  required LocationAddressInput address,
  bool? isActive,
}) => {
  'name': name,
  'address': address.toJson(),
  'notes': notes,
  'is_active': ?isActive,
};

/// `POST /v1/locations` — `client_id` obrigatório.
Map<String, dynamic> locationCreateBody({
  required String clientId,
  required String name,
  String notes = '',
  LocationAddressInput address = LocationAddressInput.empty,
  bool? isActive,
}) => {
  'client_id': clientId,
  ..._locationFields(
    name: name,
    notes: notes,
    address: address,
    isActive: isActive,
  ),
};

/// `PATCH /v1/locations/{id}`.
Map<String, dynamic> locationUpdateBody({
  required String name,
  String notes = '',
  LocationAddressInput address = LocationAddressInput.empty,
  bool? isActive,
}) => _locationFields(
  name: name,
  notes: notes,
  address: address,
  isActive: isActive,
);

/// Endereço do local numa linha só (exibição).
String locationAddressLine(LocalLocation l) => [
  l.street,
  l.number,
  l.complement,
  l.district,
  l.city,
  l.state,
  l.postalCode,
].where((s) => s.isNotEmpty).join(', ');
