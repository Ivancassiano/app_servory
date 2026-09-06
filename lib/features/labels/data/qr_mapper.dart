import '../../../core/db/app_database.dart';
import '../../../core/network/api_parse.dart';

/// REST/sync ↔ `LocalQrCode`. O shape de `GET /v1/qr-codes/{id}` (e o objeto
/// `data` do `sync/pull`) é o schema `QRCode` do OpenAPI (spec §8-§9).
LocalQrCode qrCodeFromApiJson(
  Map<String, dynamic> j, {
  required String organizationId,
}) {
  final now = DateTime.now();
  final publicCode = j['public_code'] as String?;
  return LocalQrCode(
    id: j['id'] as String,
    organizationId: organizationId,
    // O backend manda `""` (não `null`) enquanto o código público não foi
    // gerado (etiqueta criada offline, ADR-0019) — normaliza para `null`.
    publicCode: (publicCode == null || publicCode.isEmpty) ? null : publicCode,
    status: stringOr(j['status'], 'available'),
    batchId: j['batch_id'] as String?,
    clientId: j['client_id'] as String?,
    locationId: j['location_id'] as String?,
    equipmentId: j['equipment_id'] as String?,
    assignedAt: parseApiDate(j['assigned_at']),
    createdAt: parseApiDate(j['created_at']),
    version: j['version'] as int?,
    localUpdatedAt: now,
    lastSyncedAt: now,
    syncStatus: 'synced',
    deleted: false,
  );
}

/// REST/sync ↔ `LocalQrBatch` (schema `QRBatch`). Somente leitura no app.
LocalQrBatch qrBatchFromApiJson(
  Map<String, dynamic> j, {
  required String organizationId,
}) {
  final now = DateTime.now();
  return LocalQrBatch(
    id: j['id'] as String,
    organizationId: organizationId,
    label: stringOr(j['label']),
    quantity: (j['quantity'] as num?)?.toInt() ?? 0,
    status: stringOr(j['status'], 'created'),
    reservedUserId: j['reserved_user_id'] as String?,
    reservedDeviceId: j['reserved_device_id'] as String?,
    exportCount: (j['export_count'] as num?)?.toInt() ?? 0,
    createdAt: parseApiDate(j['created_at']),
    version: j['version'] as int?,
    localUpdatedAt: now,
    lastSyncedAt: now,
    syncStatus: 'synced',
    deleted: false,
  );
}

/// Alvo de uma etiqueta — exatamente um dos três. `POST /v1/qr-codes`,
/// `.../assign` e o `payload` de sync aceitam esse mesmo shape.
class QrTarget {
  const QrTarget._(this.clientId, this.locationId, this.equipmentId);
  const QrTarget.client(String id) : this._(id, null, null);
  const QrTarget.location(String id) : this._(null, id, null);
  const QrTarget.equipment(String id) : this._(null, null, id);

  final String? clientId;
  final String? locationId;
  final String? equipmentId;

  Map<String, dynamic> toJson() => {
    'client_id': ?clientId,
    'location_id': ?locationId,
    'equipment_id': ?equipmentId,
  };

  Map<String, String> toQuery() => {
    'client_id': ?clientId,
    'location_id': ?locationId,
    'equipment_id': ?equipmentId,
  };

  @override
  bool operator ==(Object other) =>
      other is QrTarget &&
      other.clientId == clientId &&
      other.locationId == locationId &&
      other.equipmentId == equipmentId;

  @override
  int get hashCode => Object.hash(clientId, locationId, equipmentId);
}

/// Resultado de `GET /v1/qr-codes/resolve/{code}` (schema `QRCodeResolved`).
class QrResolved {
  const QrResolved({required this.code, this.entity});

  final LocalQrCode code;
  final QrResolvedEntity? entity;

  factory QrResolved.fromApiJson(
    Map<String, dynamic> j, {
    required String organizationId,
  }) {
    final entity = j['entity'] as Map<String, dynamic>?;
    return QrResolved(
      code: qrCodeFromApiJson(
        j['code'] as Map<String, dynamic>,
        organizationId: organizationId,
      ),
      entity: entity == null ? null : QrResolvedEntity.fromApiJson(entity),
    );
  }
}

class QrResolvedEntity {
  const QrResolvedEntity({
    required this.kind,
    required this.id,
    required this.name,
    this.clientId,
    this.locationId,
  });

  final String kind; // client | location | equipment
  final String id;
  final String name;
  final String? clientId;
  final String? locationId;

  factory QrResolvedEntity.fromApiJson(Map<String, dynamic> j) =>
      QrResolvedEntity(
        kind: j['kind'] as String? ?? '',
        id: j['id'] as String? ?? '',
        name: j['name'] as String? ?? '',
        clientId: j['client_id'] as String?,
        locationId: j['location_id'] as String?,
      );
}
