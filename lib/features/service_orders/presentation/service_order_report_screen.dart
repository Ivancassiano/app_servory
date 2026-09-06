import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../application/service_order_pdf.dart';
import '../application/service_order_report.dart';

/// Cópia de campo do laudo (ADR-0018 §10). Nos apps mostra o `PdfPreview` do
/// pacote `printing` (com imprimir/compartilhar embutidos, funciona offline).
/// No web o `PdfPreview` trava ao rasterizar PDFs com fontes base-14 não
/// embutidas (Helvetica) via pdf.js — então mostra só as ações, que usam o
/// renderizador nativo do navegador.
class ServiceOrderReportScreen extends ConsumerWidget {
  const ServiceOrderReportScreen({super.key, required this.serviceOrderId});

  final String serviceOrderId;

  String get _fileName =>
      'laudo-${serviceOrderId.length >= 8 ? serviceOrderId.substring(0, 8) : serviceOrderId}.pdf';

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
        data: (data) => kIsWeb
            ? _WebActions(fileName: _fileName, data: data)
            : PdfPreview(
                build: (_) => buildServiceOrderPdf(data),
                canChangePageFormat: false,
                canChangeOrientation: false,
                canDebug: false,
                pdfFileName: _fileName,
              ),
      ),
    );
  }
}

class _WebActions extends StatefulWidget {
  const _WebActions({required this.fileName, required this.data});

  final String fileName;
  final ServiceOrderReportData data;

  @override
  State<_WebActions> createState() => _WebActionsState();
}

class _WebActionsState extends State<_WebActions> {
  late final Future<Uint8List> _pdf = buildServiceOrderPdf(widget.data);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _pdf,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Não foi possível montar o laudo.\n${snap.error}'),
            ),
          );
        }
        final bytes = snap.data!;
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.picture_as_pdf_outlined, size: 64),
              const SizedBox(height: 16),
              Text(
                'Laudo pronto (${(bytes.length / 1024).toStringAsFixed(0)} KB).',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => Printing.layoutPdf(
                  onLayout: (_) => bytes,
                  name: widget.fileName,
                ),
                icon: const Icon(Icons.print_outlined),
                label: const Text('Imprimir'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () =>
                    Printing.sharePdf(bytes: bytes, filename: widget.fileName),
                icon: const Icon(Icons.download_outlined),
                label: const Text('Baixar / compartilhar'),
              ),
            ],
          ),
        );
      },
    );
  }
}
