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

/// Uma foto já capturada no aparelho — bytes lidos do arquivo local, não da
/// URL assinada do servidor (o PDF de campo tem que funcionar offline).
/// `kind`/`caption` só existem enquanto o item ainda está na fila de upload;
/// depois que a fila drena a linha some e sobra só o arquivo.
class ReportPhoto {
  const ReportPhoto({required this.bytes, this.kind, this.caption});

  final Uint8List bytes;
  final String? kind;
  final String? caption;
}

/// Tudo que o laudo de campo precisa, montado só a partir do que já está no
/// dispositivo (banco local + arquivos de anexo). Nada aqui depende de rede
/// — é essa a razão de ser da cópia local (ADR-0018 §10, GUIA-FLUTTER §10).
class ServiceOrderReportData {
  const ServiceOrderReportData({
    required this.order,
    required this.client,
    required this.location,
    required this.equipment,
    required this.parts,
    required this.photos,
    required this.signaturePng,
    required this.generatedAt,
    required this.technicianName,
    required this.organizationName,
    required this.hasPendingUploads,
  });

  final LocalServiceOrder order;
  final LocalClient? client;
  final LocalLocation? location;
  final LocalEquipment? equipment;
  final List<LocalServiceOrderPart> parts;
  final List<ReportPhoto> photos;
  final Uint8List? signaturePng;
  final DateTime generatedAt;

  /// `null` quando o app nunca conseguiu carregar `/v1/me` nesta sessão
  /// (login feito offline) — o laudo simplesmente omite a linha.
  final String? technicianName;
  final String? organizationName;

  /// Ainda há foto/assinatura na fila de upload — o laudo oficial do
  /// servidor vai divergir deste até sincronizar. O PDF avisa isso no rodapé.
  final bool hasPendingUploads;
}

/// Monta [ServiceOrderReportData] para uma ordem. `FutureProvider` (não
/// `Stream`) de propósito: o laudo é um retrato do momento em que o técnico
/// tocou "Gerar PDF", não algo que precise re-renderizar ao vivo.
final serviceOrderReportDataProvider =
    FutureProvider.family<ServiceOrderReportData, String>((ref, orderId) async {
      final db = ref.watch(appDatabaseProvider);

      final order = await (db.select(
        db.localServiceOrders,
      )..where((t) => t.id.equals(orderId))).getSingleOrNull();
      if (order == null) {
        throw StateError('Ordem $orderId não encontrada no banco local');
      }

      final client = await ref.watch(
        clientByIdProvider(order.clientId).future,
      );
      final location = order.locationId == null
          ? null
          : await ref.watch(locationByIdProvider(order.locationId!).future);
      final equipment = order.equipmentId == null
          ? null
          : await ref.watch(equipmentByIdProvider(order.equipmentId!).future);

      final parts = await (db.select(db.localServiceOrderParts)
            ..where(
              (t) =>
                  t.serviceOrderId.equals(orderId) & t.deleted.equals(false),
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

      final photos = await _readPhotos(Directory(p.join(baseDir, 'photos')), metaByPath);
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
        organizationName:
            identity?.organizationName.isNotEmpty == true
            ? identity!.organizationName
            : null,
        hasPendingUploads: queued.isNotEmpty,
      );
    });

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

/// Assinatura: "Substituir" enfileira um arquivo novo sem apagar o antigo —
/// o laudo usa o mais recente.
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
