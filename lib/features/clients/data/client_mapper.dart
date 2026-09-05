import '../../../core/db/app_database.dart';
import '../../../core/network/api_parse.dart';

/// Mapeamento REST/sync ↔ `LocalClient`. Usado tanto pelo caminho REST
/// direto (repositórios) quanto pelo `SyncEngine._upsert` — o shape de
/// `GET /v1/clients/{id}` e o de `data` no `sync/pull` são idênticos.

LocalClient clientFromApiJson(
  Map<String, dynamic> j, {
  required String organizationId,
}) {
  final now = DateTime.now();
  return LocalClient(
    id: j['id'] as String,
    organizationId: organizationId,
    kind: stringOr(j['kind'], 'legal'),
    name: stringOr(j['name']),
    legalName: stringOr(j['legal_name']),
    taxId: stringOr(j['tax_id']),
    phone: stringOr(j['phone']),
    email: stringOr(j['email']),
    contactPerson: stringOr(j['contact_person']),
    internalNotes: maskable(j['internal_notes']),
    version: j['version'] as int?,
    createdAt: parseApiDate(j['created_at']),
    updatedAt: parseApiDate(j['updated_at']),
    localUpdatedAt: now,
    lastSyncedAt: now,
    syncStatus: 'synced',
    deleted: false,
  );
}

/// Corpo de `POST /v1/clients` e do `payload` de uma operação de sync
/// `create` (mesmos campos). `kind` só é aceito na criação (imutável).
Map<String, dynamic> clientCreateBody({
  required String kind,
  required String name,
  required String phone,
}) => {'kind': kind, 'name': name, 'phone': phone};

/// Campos alteráveis pelo formulário. Para REST o chamador acrescenta
/// `version`; para a fila de sync, `version` vai como `base_version` (fora
/// do payload — o backend rejeita chave desconhecida).
Map<String, dynamic> clientUpdateBody({
  required String name,
  required String phone,
}) => {'name': name, 'phone': phone};
