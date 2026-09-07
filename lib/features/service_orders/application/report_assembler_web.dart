import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../clients/application/clients_provider.dart';
import '../../items/application/items_provider.dart';
import '../../me/application/me_provider.dart';
import '../../me/application/person_provider.dart';
import '../../attachments/application/service_order_attachments_provider.dart';
import 'report_items.dart';
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
  final item = order.itemId == null
      ? null
      : await ref.watch(itemByIdProvider(order.itemId!).future);
  final itemType = item?.itemTypeId == null
      ? null
      : (ref.watch(itemTypeListProvider).value ?? const [])
          .where((t) => t.id == item!.itemTypeId)
          .firstOrNull;
  final allParts = await ref.watch(servicePartsProvider(orderId).future);
  final itemRows = await ref.watch(serviceItemsProvider(orderId).future);
  final catalog = {
    for (final i in ref.watch(itemListProvider).value ?? const <LocalItem>[])
      i.id: i,
  };
  final download = Dio(); // sem interceptor de auth — URLs já são assinadas

  final orderPhotos = await ref.watch(orderPhotosProvider(orderId).future);
  final allPhotos = <ReportPhoto>[];
  for (final photo in orderPhotos) {
    try {
      final bytes = await _downloadBytes(download, photo.downloadUrl);
      allPhotos.add(
        ReportPhoto(
          bytes: bytes,
          kind: photo.kind,
          caption: photo.caption,
          serviceOrderItemId: photo.serviceOrderItemId,
        ),
      );
    } catch (_) {
      // uma foto indisponível não derruba o laudo
    }
  }

  final split = partitionReport(
    allParts: allParts,
    itemRows: itemRows,
    catalogById: catalog,
    allPhotos: allPhotos,
  );
  final parts = split.generalParts;
  final photos = split.generalPhotos;

  final signature = await ref.watch(orderSignatureProvider(orderId).future);
  Uint8List? signaturePng;
  if (signature != null) {
    try {
      signaturePng = await _downloadBytes(download, signature.downloadUrl);
    } catch (_) {}
  }

  final identity = ref.read(identityProvider).asData?.value;

  String? registration;
  try {
    final reg = (await ref.watch(
      myPersonProvider.future,
    )).professionalRegistration;
    registration = reg.isNotEmpty ? reg : null;
  } catch (_) {}

  return ServiceOrderReportData(
    order: order,
    client: client,
    item: item,
    itemType: itemType,
    parts: parts,
    items: split.items,
    photos: photos,
    signaturePng: signaturePng,
    generatedAt: DateTime.now(),
    technicianName: identity?.name.isNotEmpty == true ? identity!.name : null,
    technicianRegistration: registration,
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
