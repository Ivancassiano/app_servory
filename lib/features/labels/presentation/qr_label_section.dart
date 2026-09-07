import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/app_database.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../data/qr_mapper.dart';
import '../data/qr_repository.dart';
import 'qr_scan_sheet.dart';

/// Seção "Etiqueta" das telas de detalhe (cliente / local / equipamento):
/// mostra o código público da etiqueta ativa e as ações de vincular /
/// substituir / desativar / imprimir (Fatia 3b).
class QrLabelSection extends ConsumerStatefulWidget {
  const QrLabelSection({super.key, required this.target, this.entityLabel});

  final QrTarget target;

  /// Nome do registro (cliente/local/equipamento) — impresso na etiqueta.
  final String? entityLabel;

  @override
  ConsumerState<QrLabelSection> createState() => _QrLabelSectionState();
}

class _QrLabelSectionState extends ConsumerState<QrLabelSection> {
  bool _busy = false;

  QrRepository get _repo => ref.read(qrRepositoryProvider);

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _run(Future<void> Function() action, String okMsg) async {
    setState(() => _busy = true);
    try {
      await action();
      ref.invalidate(activeQrCodeProvider(widget.target));
      _snack(okMsg);
    } on QrActionException catch (e) {
      _snack(e.friendlyMessage);
    } on ApiException catch (e) {
      _snack(e.friendlyMessage);
    } catch (_) {
      _snack('Não foi possível concluir a ação.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Escanear/digitar um código e vinculá-lo a este registro.
  Future<void> _addByScan() async {
    final code = await showQrScanSheet(context);
    if (code == null || !mounted) return;
    await _run(() async {
      final resolved = await _repo.resolve(code);
      final entity = resolved.entity;
      if (entity != null) {
        throw QrActionException(
          'Esta etiqueta já está vinculada a "${entity.name}". Para usá-la '
          'aqui é preciso substituir a etiqueta física.',
        );
      }
      await _repo.assign(
        codeId: resolved.code.id,
        target: widget.target,
        baseVersion: resolved.code.version,
      );
    }, 'Etiqueta vinculada.');
  }

  Future<void> _generateNew() =>
      _run(() => _repo.createBound(widget.target), 'Etiqueta gerada.');

  Future<void> _deactivate(LocalQrCode active) async {
    final ok = await _confirm(
      'Desativar etiqueta?',
      'A etiqueta "${active.publicCode ?? active.id}" deixa de identificar '
      'este registro.',
    );
    if (ok != true) return;
    await _run(
      () => _repo.deactivate(codeId: active.id, baseVersion: active.version),
      'Etiqueta desativada.',
    );
  }

  Future<void> _replaceByScan(LocalQrCode active) async {
    final code = await showQrScanSheet(context);
    if (code == null || !mounted) return;
    await _run(() async {
      final resolved = await _repo.resolve(code);
      if (resolved.entity != null) {
        throw QrActionException(
          'Esta etiqueta já está em uso ("${resolved.entity!.name}").',
        );
      }
      await _repo.replace(
        codeId: active.id,
        newCodeId: resolved.code.id,
        baseVersion: active.version,
      );
    }, 'Etiqueta substituída.');
  }

  Future<void> _replaceGenerated(LocalQrCode active) => _run(
    () => _repo.replace(codeId: active.id, baseVersion: active.version),
    'Nova etiqueta gerada.',
  );

  void _print(LocalQrCode active) {
    final code = active.publicCode;
    if (code == null) return;
    final t = widget.target;
    final kindLabel = t.clientId != null
        ? 'Cliente'
        : t.itemId != null
        ? 'Item'
        : null;
    context.push(
      Uri(
        path: '/qr-label',
        queryParameters: {
          'code': code,
          'title': ?widget.entityLabel,
          'subtitle': ?kindLabel,
        },
      ).toString(),
    );
  }

  Future<bool?> _confirm(String title, String body) => showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(body),
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

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(activeQrCodeProvider(widget.target));
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Etiqueta', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        async.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(),
          ),
          error: (_, _) => Text(
            'Não foi possível carregar a etiqueta.',
            style: TextStyle(color: theme.colorScheme.error),
          ),
          data: (code) => code == null
              ? _NoLabel(busy: _busy, onScan: _addByScan, onGenerate: _generateNew)
              : _LabelCard(
                  code: code,
                  busy: _busy,
                  onPrint: code.publicCode == null ? null : () => _print(code),
                  onReplaceScan: () => _replaceByScan(code),
                  onReplaceGenerate: () => _replaceGenerated(code),
                  onDeactivate: () => _deactivate(code),
                ),
        ),
      ],
    );
  }
}

class _NoLabel extends StatelessWidget {
  const _NoLabel({
    required this.busy,
    required this.onScan,
    required this.onGenerate,
  });

  final bool busy;
  final VoidCallback onScan;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.qr_code_2_outlined),
              title: Text('Nenhuma etiqueta'),
              subtitle: Text('Este registro ainda não tem uma etiqueta.'),
            ),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: busy ? null : onScan,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Escanear / digitar'),
                ),
                TextButton.icon(
                  onPressed: busy ? null : onGenerate,
                  icon: const Icon(Icons.add),
                  label: const Text('Gerar nova'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LabelCard extends StatelessWidget {
  const _LabelCard({
    required this.code,
    required this.busy,
    required this.onPrint,
    required this.onReplaceScan,
    required this.onReplaceGenerate,
    required this.onDeactivate,
  });

  final LocalQrCode code;
  final bool busy;
  final VoidCallback? onPrint;
  final VoidCallback onReplaceScan;
  final VoidCallback onReplaceGenerate;
  final VoidCallback onDeactivate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pending = code.syncStatus == 'pending';
    final conflict = code.syncStatus == 'conflict';
    final display = code.publicCode ?? '(código pendente de sincronização)';

    return Card(
      color: conflict ? theme.colorScheme.errorContainer : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                conflict ? Icons.warning_amber : Icons.qr_code_2,
                color: conflict ? theme.colorScheme.error : null,
              ),
              title: SelectableText(
                display,
                style: const TextStyle(
                  fontFeatures: [FontFeature.tabularFigures()],
                  letterSpacing: 0.5,
                ),
              ),
              subtitle: Text(
                conflict
                    ? 'Esta etiqueta já está em uso em outro registro. Será '
                          'necessário substituir a etiqueta física por uma nova.'
                    : pending
                    ? 'Vínculo pendente de sincronização.'
                    : 'Etiqueta ativa.',
                style: conflict
                    ? TextStyle(color: theme.colorScheme.onErrorContainer)
                    : null,
              ),
              trailing: code.publicCode == null
                  ? null
                  : IconButton(
                      tooltip: 'Copiar código',
                      icon: const Icon(Icons.copy_outlined),
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: code.publicCode!),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Código copiado.')),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 4),
            IntrinsicHeight(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (onPrint != null && !conflict) ...[
                    AspectRatio(
                      aspectRatio: 1,
                      child: FilledButton(
                        onPressed: onPrint,
                        style: FilledButton.styleFrom(
                          backgroundColor: BrandColor.ink,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                        child: const Icon(Icons.print_outlined, size: 20),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  FilledButton.tonalIcon(
                    onPressed: busy ? null : onReplaceScan,
                    icon: const Icon(Icons.qr_code_scanner),
                    label: Text(
                      conflict ? 'Substituir etiqueta' : 'Substituir',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                if (!conflict)
                  TextButton(
                    onPressed: busy ? null : onReplaceGenerate,
                    child: const Text('Substituir por uma nova'),
                  ),
                if (!conflict)
                  TextButton(
                    onPressed: busy ? null : onDeactivate,
                    child: const Text('Desativar'),
                  ),
                if (conflict)
                  TextButton(
                    onPressed: busy ? null : onReplaceGenerate,
                    child: const Text('Gerar nova'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
