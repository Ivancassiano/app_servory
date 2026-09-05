import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../application/service_order_pdf.dart';
import '../application/service_order_report.dart';

/// Pré-visualização + compartilhar/imprimir da cópia de campo do laudo
/// (ADR-0018 §10). `PdfPreview` do pacote `printing` já traz os botões de
/// compartilhar e imprimir; compartilhar usa a folha nativa do SO e
/// funciona offline (entregar por Bluetooth, salvar em Arquivos, etc.).
class ServiceOrderReportScreen extends ConsumerWidget {
  const ServiceOrderReportScreen({super.key, required this.serviceOrderId});

  final String serviceOrderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(serviceOrderReportDataProvider(serviceOrderId));

    return Scaffold(
      appBar: AppBar(title: const Text('Laudo — cópia de campo')),
      body: dataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Não foi possível montar o laudo.\n$e',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (data) => PdfPreview(
          build: (_) => buildServiceOrderPdf(data),
          canChangePageFormat: false,
          canChangeOrientation: false,
          canDebug: false,
          pdfFileName:
              'laudo-${serviceOrderId.length >= 8 ? serviceOrderId.substring(0, 8) : serviceOrderId}.pdf',
        ),
      ),
    );
  }
}
