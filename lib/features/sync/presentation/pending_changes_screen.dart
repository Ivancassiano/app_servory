import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/app_database.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/brand_app_bar.dart';
import '../application/pending_target.dart';
import '../application/sync_provider.dart';

/// Lista o que foi feito offline e ainda não subiu — com o motivo do erro e a
/// opção de reenviar ou descartar item a item. Chega pela faixa de status
/// ("N alterações não enviadas → toque") e por Configurações. Tocar numa
/// alteração leva direto ao registro para corrigir o que o servidor recusou.
class PendingChangesScreen extends ConsumerWidget {
  const PendingChangesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outbox = ref.watch(pendingOutboxProvider).value ?? const [];
    final uploads = ref.watch(pendingUploadsListProvider).value ?? const [];
    final syncing = ref.watch(syncRunnerProvider).isLoading;
    final total = outbox.length + uploads.length;

    return Scaffold(
      appBar: brandAppBar(title: 'Alterações pendentes'),
      body: total == 0
          ? const _Empty()
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                Text(
                  'Feito offline e ainda não enviado. Toque em "Tentar enviar" '
                  'quando estiver com internet; se algo não sobe de jeito '
                  'nenhum, descarte.',
                  style: BrandText.listMeta,
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: syncing
                      ? null
                      : () => ref
                            .read(pendingChangesControllerProvider)
                            .retryAll(),
                  icon: syncing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cloud_upload_outlined),
                  label: Text(syncing ? 'Enviando…' : 'Tentar enviar tudo'),
                ),
                const SizedBox(height: 16),
                for (final row in outbox)
                  _OutboxTile(row: row, key: ValueKey('o:${row.operationId}')),
                for (final up in uploads)
                  _UploadTile(row: up, key: ValueKey('u:${up.id}')),
              ],
            ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, size: 48, color: BrandColor.blue),
            SizedBox(height: 12),
            Text('Tudo enviado.', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

const _entityLabels = {
  'client': 'Cliente',
  'location': 'Local',
  'item': 'Item',
  'item_field_value': 'Campo do item',
  'service_order': 'Ordem de serviço',
  'service_order_item': 'Item da ordem',
  'service_order_part': 'Peça da ordem',
  'service_order_recommendation': 'Recomendação',
  'task': 'Tarefa',
  'qr_code': 'Etiqueta',
};

const _opLabels = {
  'create': 'criar',
  'update': 'editar',
  'delete': 'excluir',
  'complete': 'concluir',
  'cancel': 'cancelar',
  'reopen': 'reabrir',
  'start': 'iniciar',
};

String _since(DateTime at) {
  final d = DateTime.now().difference(at);
  if (d.inMinutes < 1) return 'agora há pouco';
  if (d.inMinutes < 60) return 'há ${d.inMinutes} min';
  if (d.inHours < 24) return 'há ${d.inHours} h';
  return 'há ${d.inDays} d';
}

class _Card extends StatelessWidget {
  const _Card({
    required this.title,
    required this.meta,
    this.subject,
    this.error,
    this.onOpen,
    required this.onDiscard,
  });

  final String title;
  final String meta;

  /// Qual registro é (nome do item/campo…) — a outbox só guarda ids.
  final String? subject;
  final String? error;

  /// Vai até o lugar onde dá para corrigir; `null` = sem tela de destino.
  final VoidCallback? onOpen;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final hasError = error != null && error!.isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.fromBorderSide(
          BorderSide(
            color: hasError ? BrandColor.errorText : BrandColor.border,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: InkWell(
              onTap: onOpen,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 0, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Space Grotesk',
                        fontWeight: FontWeight.w500,
                        color: BrandColor.ink,
                      ),
                    ),
                    if (subject != null) ...[
                      const SizedBox(height: 2),
                      Text(subject!, style: BrandText.listMeta),
                    ],
                    const SizedBox(height: 2),
                    Text(meta, style: BrandText.listMeta),
                    if (hasError) ...[
                      const SizedBox(height: 4),
                      Text(
                        error!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: BrandColor.errorText,
                        ),
                      ),
                    ],
                    if (onOpen != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        hasError
                            ? 'Toque para corrigir →'
                            : 'Toque para abrir →',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: BrandColor.blue,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            color: BrandColor.textTertiary,
            onPressed: onDiscard,
          ),
        ],
      ),
    );
  }
}

/// Destino (rota + nome do registro) de cada operação da outbox.
final _pendingTargetProvider = FutureProvider.autoDispose
    .family<PendingTarget?, SyncOutboxData>(
      (ref, op) => resolvePendingTarget(ref.watch(appDatabaseProvider), op),
    );

class _OutboxTile extends ConsumerWidget {
  const _OutboxTile({required this.row, super.key});

  final SyncOutboxData row;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entity = _entityLabels[row.entityType] ?? row.entityType;
    final op = _opLabels[row.operationType] ?? row.operationType;
    final attempts = row.attempts > 0 ? ' · ${row.attempts} tentativa(s)' : '';
    final target = ref.watch(_pendingTargetProvider(row)).value;
    return _Card(
      title: '$entity • $op',
      subject: target?.subject,
      meta: '${_since(row.occurredAt)}$attempts',
      error: row.lastError == null ? null : _errorLine(row.lastError!),
      onOpen: target == null ? null : () => context.push(target.route),
      onDiscard: () => _confirmDiscard(
        context,
        onYes: () => ref
            .read(pendingChangesControllerProvider)
            .discardOutbox(row.operationId),
      ),
    );
  }
}

class _UploadTile extends ConsumerWidget {
  const _UploadTile({required this.row, super.key});

  final UploadQueueData row;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final what = row.kind == 'signature' ? 'Assinatura' : 'Foto';
    final caption = (row.caption ?? '').isEmpty ? '' : ' "${row.caption}"';
    final attempts = row.attempts > 0 ? ' · ${row.attempts} tentativa(s)' : '';
    return _Card(
      title: '$what$caption • enviar',
      meta: '${_since(row.createdAt)}$attempts',
      error: row.lastError,
      onDiscard: () => _confirmDiscard(
        context,
        onYes: () =>
            ref.read(pendingChangesControllerProvider).discardUpload(row.id),
      ),
    );
  }
}

Future<void> _confirmDiscard(
  BuildContext context, {
  required Future<void> Function() onYes,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Descartar alteração?'),
      content: const Text(
        'O que você fez offline nesse item será perdido e não pode ser '
        'desfeito.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Descartar'),
        ),
      ],
    ),
  );
  if (ok != true) return;
  try {
    await onYes();
  } catch (_) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Não foi possível descartar agora.')),
    );
  }
}

/// Mensagem amigável do código de erro + o código cru (ajuda a diagnosticar
/// um caso preso).
String _errorLine(String code) {
  final friendly = ApiException(code: code, message: '').friendlyMessage;
  return friendly.contains(code) ? friendly : '$friendly  ·  $code';
}
