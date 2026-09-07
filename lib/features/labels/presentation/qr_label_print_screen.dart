import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';

import '../../companies/data/company_repository.dart';
import '../../reference/data/reference_repository.dart';
import '../application/qr_label_pdf.dart';
import '../data/label_template_repository.dart';

/// Pré-visualização + imprimir / compartilhar de uma etiqueta única. Mesmo
/// padrão do laudo (`ServiceOrderReportScreen`): `PdfPreview` no nativo, só
/// as ações no web (o `PdfPreview` trava ao rasterizar no navegador).
///
/// O seletor "Texto da etiqueta" reaproveita a mesma ideia da folha por lote
/// (ADR-0016/0017): empresa emissora **ou** um modelo salvo — o texto vai
/// impresso ao lado do QR.
class QrLabelPrintScreen extends ConsumerStatefulWidget {
  const QrLabelPrintScreen({
    super.key,
    required this.publicCode,
    this.title,
    this.subtitle,
  });

  final String publicCode;
  final String? title;
  final String? subtitle;

  @override
  ConsumerState<QrLabelPrintScreen> createState() => _QrLabelPrintScreenState();
}

class _QrLabelPrintScreenState extends ConsumerState<QrLabelPrintScreen> {
  /// `co:<id>` (empresa) · `tp:<id>` (modelo) · null.
  String? _source;

  String get _fileName => 'etiqueta-${widget.publicCode}.pdf';

  @override
  void initState() {
    super.initState();
    // Melhor esforço: aquece as listas de empresa (dado de referência) e de
    // modelos de etiqueta pro seletor.
    Future.microtask(() {
      ref.read(referenceDataRepositoryProvider).refresh(ReferenceKind.company);
      ref.read(labelTemplateRepositoryProvider).refresh();
    });
  }

  String? _resolveMessage(List<Company> companies, List<LabelTemplate> tpls) {
    final s = _source;
    if (s == null) return null;
    if (s.startsWith('tp:')) {
      final id = s.substring(3);
      for (final t in tpls) {
        if (t.id == id) return t.body;
      }
      return null;
    }
    if (s.startsWith('co:')) {
      final id = s.substring(3);
      for (final c in companies) {
        if (c.id != id) continue;
        return [
          c.legalName.isNotEmpty ? c.legalName : c.name,
          c.address,
          c.phone,
        ].where((l) => l.trim().isNotEmpty).join('\n');
      }
    }
    return null;
  }

  Future<Uint8List> _build(String? message) => buildQrLabelPdf(
    publicCode: widget.publicCode,
    title: widget.title,
    subtitle: widget.subtitle,
    message: message,
  );

  @override
  Widget build(BuildContext context) {
    final companies = ref.watch(companyListProvider).value ?? const <Company>[];
    final templates =
        ref.watch(labelTemplateListProvider).value ?? const <LabelTemplate>[];
    final message = _resolveMessage(companies, templates);

    return Scaffold(
      appBar: AppBar(title: const Text('Etiqueta')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String?>(
                  initialValue: _source,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Texto da etiqueta (opcional)',
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('—')),
                    for (final c in companies)
                      DropdownMenuItem(
                        value: 'co:${c.id}',
                        child: Text(
                          'Empresa: ${c.name}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    for (final t in templates)
                      DropdownMenuItem(
                        value: 'tp:${t.id}',
                        child: Text(
                          'Modelo: ${t.name}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (v) => setState(() => _source = v),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => context.push('/label-templates'),
                    icon: const Icon(Icons.edit_note),
                    label: const Text('Criar / gerenciar modelos'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: kIsWeb
                ? _WebActions(
                    key: ValueKey(_source),
                    fileName: _fileName,
                    build: () => _build(message),
                  )
                : PdfPreview(
                    key: ValueKey(_source),
                    build: (_) => _build(message),
                    canChangePageFormat: false,
                    canChangeOrientation: false,
                    canDebug: false,
                    pdfFileName: _fileName,
                  ),
          ),
        ],
      ),
    );
  }
}

class _WebActions extends StatefulWidget {
  const _WebActions({super.key, required this.fileName, required this.build});

  final String fileName;
  final Future<Uint8List> Function() build;

  @override
  State<_WebActions> createState() => _WebActionsState();
}

class _WebActionsState extends State<_WebActions> {
  late final Future<Uint8List> _pdf = widget.build();

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
              child: Text('Não foi possível gerar a etiqueta.\n${snap.error}'),
            ),
          );
        }
        final bytes = snap.data!;
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.qr_code_2_outlined, size: 64),
              const SizedBox(height: 16),
              Text(
                'Etiqueta pronta.',
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
