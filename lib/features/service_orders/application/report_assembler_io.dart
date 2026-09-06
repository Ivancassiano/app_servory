import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/db/app_database.dart';
import '../../clients/application/clients_provider.dart';
import '../../equipments/application/equipments_provider.dart';
import '../../locations/application/locations_provider.dart';
import '../../me/application/me_provider.dart';
import '../../sync/application/sync_provider.dart';
import 'service_order_report.dart';

/// Nativo: monta o laudo do que está no dispositivo (banco local +
/// arquivos de anexo) — funciona offline.
Future<ServiceOrderReportData> assembleServiceOrderReport(
  Ref ref,
  String orderId,
) async {
  final db = ref.watch(appDatabaseProvider);

  final order = await (db.select(
    db.localServiceOrders,
  )..where((t) => t.id.equals(orderId))).getSingleOrNull();
  if (order == null) {
    throw StateError('Ordem $orderId não encontrada no banco local');
  }

  final client = await ref.watch(clientByIdProvider(order.clientId).future);
  final location = order.locationId == null
      ? null
      : await ref.watch(locationByIdProvider(order.locationId!).future);
  final equipment = order.equipmentId == null
      ? null
      : await ref.watch(equipmentByIdProvider(order.equipmentId!).future);

  final parts = await (db.select(db.localServiceOrderParts)
        ..where(
          (t) => t.serviceOrderId.equals(orderId) & t.deleted.equals(false),
        )
        ..orderBy([(t) => OrderingTerm(expression: t.localUpdatedAt)]))
      .get();

  final queued = await (db.select(
    db.uploadQueue,
  )..where((t) => t.serviceOrderId.equals(orderId))).get();
  final metaByPath = {for (final q in queued) q.filePath: q};

  final baseDir = p.join(
    (await getApplicationDocumentsDirectory()).path,
    'attachments',
    orderId,
  );

  final photos = await _readPhotos(
    Directory(p.join(baseDir, 'photos')),
    metaByPath,
  );
  final signaturePng = await _readLatestFile(
    Directory(p.join(baseDir, 'signature')),
  );

  final identity = ref.read(identityProvider).asData?.value;

  return ServiceOrderReportData(
    order: order,
    client: client,
    location: location,
    equipment: equipment,
    parts: parts,
    photos: photos,
    signaturePng: signaturePng,
    generatedAt: DateTime.now(),
    technicianName: identity?.name.isNotEmpty == true ? identity!.name : null,
    organizationName: identity?.organizationName.isNotEmpty == true
        ? identity!.organizationName
        : null,
    hasPendingUploads: queued.isNotEmpty,
  );
}

Future<List<ReportPhoto>> _readPhotos(
  Directory dir,
  Map<String, UploadQueueData> metaByPath,
) async {
  if (!await dir.exists()) return const [];
  final files = <File>[
    for (final e in await dir.list().toList())
      if (e is File && _isImage(e.path)) e,
  ];
  files.sort((a, b) => a.statSync().modified.compareTo(b.statSync().modified));
  return [
    for (final f in files)
      ReportPhoto(
        bytes: await f.readAsBytes(),
        kind: metaByPath[f.path]?.photoKind,
        caption: metaByPath[f.path]?.caption,
      ),
  ];
}

Future<Uint8List?> _readLatestFile(Directory dir) async {
  if (!await dir.exists()) return null;
  final files = <File>[
    for (final e in await dir.list().toList())
      if (e is File && _isImage(e.path)) e,
  ];
  if (files.isEmpty) return null;
  files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
  return files.first.readAsBytes();
}

bool _isImage(String path) {
  final ext = p.extension(path).toLowerCase();
  return ext == '.png' || ext == '.jpg' || ext == '.jpeg' || ext == '.webp';
}
