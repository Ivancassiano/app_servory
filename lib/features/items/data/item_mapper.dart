import '../../../core/db/app_database.dart';
import '../../../core/network/api_parse.dart';

/// REST/sync ↔ `LocalItem` (a fusão local+equipamento). A resposta (`GET` e
/// `data` de sync) traz o endereço **plano** (`postal_code`, `street`, …); só
/// o corpo de `POST/PATCH` aninha sob `address`. `serial_number`/`cost` são
/// mascaráveis (nulo = sem permissão de leitura).
LocalItem itemFromApiJson(
  Map<String, dynamic> j, {
  required String organizationId,
}) {
  final now = DateTime.now();
  return LocalItem(
    id: j['id'] as String,
    organizationId: organizationId,
    clientId: stringOr(j['client_id']),
    parentItemId: j['parent_item_id'] as String?,
    itemTypeId: j['item_type_id'] as String?,
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

/// Endereço estruturado. O corpo de `POST/PATCH` (e o payload de sync) aninha
/// sob `address`; a resposta devolve plano. Mandamos sempre os sete campos
/// para que limpar um no formulário limpe no servidor.
class ItemAddressInput {
  const ItemAddressInput({
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

  static const empty = ItemAddressInput();

  bool get isEmpty =>
      postalCode.isEmpty &&
      street.isEmpty &&
      number.isEmpty &&
      complement.isEmpty &&
      district.isEmpty &&
      city.isEmpty &&
      state.isEmpty;

  factory ItemAddressInput.of(LocalItem i) => ItemAddressInput(
    postalCode: i.postalCode,
    street: i.street,
    number: i.number,
    complement: i.complement,
    district: i.district,
    city: i.city,
    state: i.state,
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

/// Campos comuns de `ItemInput` (usados por create e update).
Map<String, dynamic> _itemFields({
  required String name,
  required String contactPerson,
  required String phone,
  required String accessInstructions,
  required String brand,
  required String model,
  required String serialNumber,
  required String internalLocation,
  String? installedAt,
  String? cost,
  required String notes,
  required ItemAddressInput address,
  String? itemTypeId,
}) => {
  'name': name,
  'address': address.toJson(),
  'contact_person': contactPerson,
  'phone': phone,
  'access_instructions': accessInstructions,
  'brand': brand,
  'model': model,
  'serial_number': serialNumber,
  'internal_location': internalLocation,
  'installed_at': installedAt,
  'cost': cost,
  'notes': notes,
  'item_type_id': ?(itemTypeId != null && itemTypeId.isNotEmpty
      ? itemTypeId
      : null),
};

/// `POST /v1/items` — `client_id` e `name` obrigatórios.
Map<String, dynamic> itemCreateBody({
  required String clientId,
  String? parentItemId,
  String? itemTypeId,
  required String name,
  String contactPerson = '',
  String phone = '',
  String accessInstructions = '',
  String brand = '',
  String model = '',
  String serialNumber = '',
  String internalLocation = '',
  String? installedAt,
  String? cost,
  String notes = '',
  ItemAddressInput address = ItemAddressInput.empty,
}) => {
  'client_id': clientId,
  'parent_item_id': ?parentItemId,
  ..._itemFields(
    name: name,
    contactPerson: contactPerson,
    phone: phone,
    accessInstructions: accessInstructions,
    brand: brand,
    model: model,
    serialNumber: serialNumber,
    internalLocation: internalLocation,
    installedAt: installedAt,
    cost: cost,
    notes: notes,
    address: address,
    itemTypeId: itemTypeId,
  ),
};

/// `PATCH /v1/items/{id}` — campos de topo + endereço aninhado.
Map<String, dynamic> itemUpdateBody({
  String? itemTypeId,
  required String name,
  String contactPerson = '',
  String phone = '',
  String accessInstructions = '',
  String brand = '',
  String model = '',
  String serialNumber = '',
  String internalLocation = '',
  String? installedAt,
  String? cost,
  String notes = '',
  ItemAddressInput address = ItemAddressInput.empty,
}) => _itemFields(
  name: name,
  contactPerson: contactPerson,
  phone: phone,
  accessInstructions: accessInstructions,
  brand: brand,
  model: model,
  serialNumber: serialNumber,
  internalLocation: internalLocation,
  installedAt: installedAt,
  cost: cost,
  notes: notes,
  address: address,
  itemTypeId: itemTypeId,
);
