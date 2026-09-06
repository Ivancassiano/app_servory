import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../clients/application/clients_provider.dart';
import '../../equipments/application/equipments_provider.dart';
import '../../locations/application/locations_provider.dart';
import '../../me/application/me_provider.dart';
import '../../attachments/application/service_order_attachments_provider.dart';
import 'service_order_report.dart';
import 'service_orders_provider.dart';

/// Web: monta o laudo direto do backend. Fotos/assinatura vêm por URL
/// assinada (baixadas aqui como bytes para o mesmo `buildServiceOrderPdf`).
Future<ServiceOrderReportData> assembleServiceOrderReport(
  Ref ref,
  String orderId,
) async {
  final order = await ref.watch(serviceOrderByIdProvider(orderId).future);
  if (order == null) {
    throw StateError('Ordem $orderId não encontrada');
  }

  final client = await ref.watch(clientByIdProvider(order.clientId).future);
  final location = order.locationId == null
      ? null
      : await ref.watch(locationByIdProvider(order.locationId!).future);
  final equipment = order.equipmentId == null
      ? null
      : await ref.watch(equipmentByIdProvider(order.equipmentId!).future);
  final parts = await ref.watch(servicePartsProvider(orderId).future);

  final download = Dio(); // sem interceptor de auth — URLs já são assinadas

  final orderPhotos = await ref.watch(orderPhotosProvider(orderId).future);
  final photos = <ReportPhoto>[];
  for (final photo in orderPhotos) {
    try {
      final bytes = await _downloadBytes(download, photo.downloadUrl);
      photos.add(
        ReportPhoto(bytes: bytes, kind: photo.kind, caption: photo.caption),
      );
    } catch (_) {
      // uma foto indisponível não derruba o laudo
    }
  }

  final signature = await ref.watch(orderSignatureProvider(orderId).future);
  Uint8List? signaturePng;
  if (signature != null) {
    try {
      signaturePng = await _downloadBytes(download, signature.downloadUrl);
    } catch (_) {}
  }

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
    hasPendingUploads: false,
  );
}

Future<Uint8List> _downloadBytes(Dio dio, String url) async {
  final r = await dio.get<List<int>>(
    url,
    options: Options(responseType: ResponseType.bytes),
  );
  return Uint8List.fromList(r.data ?? const []);
}
