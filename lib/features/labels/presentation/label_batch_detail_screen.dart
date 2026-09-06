import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../core/db/app_database.dart';
import '../../reference/data/reference_repository.dart';
import '../data/label_batch_repository.dart';

final _batchByIdProvider = Provider.family<LocalQrBatch?, String>((ref, id) {
  final list = ref.watch(labelBatchListProvider).value ?? const [];
  for (final b in list) {
    if (b.id == id) return b;
  }
  return null;
});

const _statusLabel = {
  'created': 'Criado',
  'reserved': 'Reservado',
  'issued': 'Emitido',
  'lost': 'Perdido',
};

class LabelBatchDetailScreen extends ConsumerStatefulWidget {
  const LabelBatchDetailScreen({super.key, required this.batchId});

  final String batchId;

  @override
  ConsumerState<LabelBatchDetailScreen> createState() =>
      _LabelBatchDetailScreenState();
}

class _LabelBatchDetailScreenState
    extends ConsumerState<LabelBatchDetailScreen> {
  bool _busy = false;

  LabelBatchRepository get _repo => ref.read(labelBatchRepositoryProvider);

  @override
  void initState() {
    super.initState();
    // Empresas emissoras para o seletor do PDF (dado de referência REST).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref
            .read(referenceDataRepositoryProvider)
            .refresh(ReferenceKind.company)
            .ignore();
      }
    });
  }

  Future<void> _run(Future<void> Function() action, String ok) async {
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível concluir a ação.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final batch = ref.watch(_batchByIdProvider(widget.batchId));
    if (batch == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Lote não encontrado.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(batch.label.isNotEmpty ? batch.label : 'Lote'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Situação'),
                    trailing: Chip(
                      label: Text(
                        _statusLabel[batch.status] ?? batch.status,
                      ),
                    ),
                  ),
                  ListTile(
                    title: const Text('Quantidade'),
                    trailing: Text('${batch.quantity}'),
                  ),
                  ListTile(
                    title: const Text('Exportações'),
                    trailing: Text('${batch.exportCount}'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_busy) const LinearProgressIndicator(),
            if (batch.status == 'created')
              _ActionButton(
                icon: Icons.person_pin_circle_outlined,
                label: 'Reservar para este aparelho',
                onPressed: _busy
                    ? null
                    : () => _run(
                        () => _repo.reserve(batch.id),
                        'Lote reservado.',
                      ),
              ),
            if (batch.status == 'created' || batch.status == 'reserved')
              _ActionButton(
                icon: Icons.outbox_outlined,
                label: batch.exportCount > 0
                    ? 'Reexportar (marcar emitido)'
                    : 'Exportar (marcar emitido)',
                onPressed: _busy
                    ? null
                    : () => _run(
                        () => _repo.export(batch.id),
                        'Lote exportado.',
                      ),
              ),
            if (batch.status != 'lost')
              _ActionButton(
                icon: Icons.report_gmailerrorred_outlined,
                label: 'Marcar lote como perdido',
                destructive: true,
                onPressed: _busy
                    ? null
                    : () async {
                        final ok = await _confirmLost();
                        if (ok == true) {
                          await _run(
                            () => _repo.markLost(batch.id),
                            'Lote marcado como perdido.',
                          );
                        }
                      },
              ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Folha de etiquetas (PDF)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              batch.status == 'issued' || batch.exportCount > 0
                  ? 'Escolha o formato e a empresa emissora.'
                  : 'Exporte o lote antes de gerar a folha.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed:
                  _busy || !(batch.status == 'issued' || batch.exportCount > 0)
                  ? null
                  : () => _openPdfFlow(batch),
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Gerar folha PDF'),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _confirmLost() => showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Marcar lote como perdido?'),
      content: const Text(
        'As etiquetas ainda não vinculadas viram "perdidas" e não podem '
        'mais ser usadas. Ação irreversível.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Confirmar'),
        ),
      ],
    ),
  );

  Future<void> _openPdfFlow(LocalQrBatch batch) async {
    final companies = ref.read(referenceListProvider(ReferenceKind.company)).value ??
        const <ReferenceItem>[];
    var format = 'full';
    String? companyId = companies.isNotEmpty ? companies.first.id : null;

    final go = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Folha de etiquetas',
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: format,
                decoration: const InputDecoration(labelText: 'Formato'),
                items: const [
                  DropdownMenuItem(
                    value: 'full',
                    child: Text('A4 — QR + código + texto'),
                  ),
                  DropdownMenuItem(
                    value: 'compact',
                    child: Text('A4 — só código + texto'),
                  ),
                  DropdownMenuItem(
                    value: 'thermal',
                    child: Text('Térmica 60×40 mm (bobina)'),
                  ),
                ],
                onChanged: (v) => setSheet(() => format = v ?? 'full'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                initialValue: companyId,
                decoration: const InputDecoration(
                  labelText: 'Empresa emissora (opcional)',
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('—')),
                  for (final c in companies)
                    DropdownMenuItem(value: c.id, child: Text(c.label)),
                ],
                onChanged: (v) => setSheet(() => companyId = v),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Gerar'),
              ),
            ],
          ),
        ),
      ),
    );
    if (go != true || !mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _LabelSheetPreview(
          batchId: batch.id,
          format: format,
          companyId: companyId,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Align(
          alignment: Alignment.centerLeft,
          child: Text(label),
        ),
        style: destructive
            ? OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              )
            : null,
      ),
    );
  }
}

class _LabelSheetPreview extends ConsumerStatefulWidget {
  const _LabelSheetPreview({
    required this.batchId,
    required this.format,
    required this.companyId,
  });

  final String batchId;
  final String format;
  final String? companyId;

  @override
  ConsumerState<_LabelSheetPreview> createState() => _LabelSheetPreviewState();
}

class _LabelSheetPreviewState extends ConsumerState<_LabelSheetPreview> {
  late final Future<Uint8List> _pdf;

  @override
  void initState() {
    super.initState();
    _pdf = ref.read(labelBatchRepositoryProvider).buildLabelSheetPdf(
          widget.batchId,
          format: widget.format,
          companyId: widget.companyId,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Folha de etiquetas')),
      body: FutureBuilder<Uint8List>(
        future: _pdf,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Gerando a folha no servidor...'),
                ],
              ),
            );
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Não foi possível gerar a folha.\n${snap.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final bytes = snap.data!;
          return PdfPreview(
            build: (_) => bytes,
            canChangePageFormat: false,
            canChangeOrientation: false,
            canDebug: false,
            pdfFileName: 'etiquetas-${widget.batchId.substring(0, 8)}.pdf',
          );
        },
      ),
    );
  }
}
