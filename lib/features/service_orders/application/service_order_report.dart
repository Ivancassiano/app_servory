import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import 'report_assembler.dart';

/// Uma foto do laudo — bytes já resolvidos (do disco no nativo, da URL
/// assinada no web). `kind`/`caption` quando disponíveis.
class ReportPhoto {
  const ReportPhoto({required this.bytes, this.kind, this.caption});

  final Uint8List bytes;
  final String? kind;
  final String? caption;
}

/// Tudo que o laudo de campo precisa. No nativo é montado do que está no
/// dispositivo (funciona offline, ADR-0018 §10); no web, direto do backend.
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

  /// `null` quando `/v1/me` nunca carregou nesta sessão (login offline).
  final String? technicianName;
  final String? organizationName;

  /// Ainda há foto/assinatura na fila de upload (só nativo) — o laudo
  /// oficial do servidor vai divergir deste até sincronizar.
  final bool hasPendingUploads;
}

/// Retrato do momento em que o técnico tocou "Gerar PDF" — `FutureProvider`
/// de propósito, não re-renderiza ao vivo.
final serviceOrderReportDataProvider =
    FutureProvider.family<ServiceOrderReportData, String>(
  (ref, orderId) => assembleServiceOrderReport(ref, orderId),
);
