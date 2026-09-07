import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/app_database.dart';
import '../application/service_orders_provider.dart';

const _statusLabels = {
  'draft': 'Rascunho',
  'open': 'Aberta',
  'in_progress': 'Em andamento',
  'completed': 'Concluída',
};

/// Data/hora de cadastro do laudo — cai pra atualização quando o servidor não
/// mandou `created_at` (registros antigos).
DateTime? _createdAt(LocalServiceOrder o) => o.createdAt ?? o.updatedAt;

String _fmtDateTime(DateTime? d) {
  if (d == null) return 'sem data';
  final l = d.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(l.day)}/${two(l.month)}/${l.year} ${two(l.hour)}:${two(l.minute)}';
}

String _statusReason(LocalServiceOrder o) {
  final status = _statusLabels[o.status] ?? o.status;
  return o.reason.isEmpty ? status : '$status · ${o.reason}';
}

/// "Laudos" numa tela de cliente/local/equipamento — as ordens de serviço
/// ligadas àquele registro, com prévia curta e um link para a lista completa
/// já filtrada. Passe exatamente um escopo.
class RelatedServiceOrdersSection extends ConsumerWidget {
  const RelatedServiceOrdersSection({
    super.key,
    this.clientId,
    this.locationId,
    this.equipmentId,
  }) : assert(
         clientId != null || locationId != null || equipmentId != null,
         'informe um escopo (cliente, local ou equipamento)',
       );

  final String? clientId;
  final String? locationId;
  final String? equipmentId;

  String get _query {
    if (clientId != null) return 'clientId=$clientId';
    if (locationId != null) return 'locationId=$locationId';
    return 'equipmentId=$equipmentId';
  }

  bool _matches(LocalServiceOrder o) =>
      (clientId == null || o.clientId == clientId) &&
      (locationId == null || o.locationId == locationId) &&
      (equipmentId == null || o.equipmentId == equipmentId);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(serviceOrderListProvider);
    final theme = Theme.of(context);

    if (async.hasError && async.value == null) {
      return Text(
        'Não foi possível carregar os laudos.',
        style: TextStyle(color: theme.colorScheme.error),
      );
    }

    final all = async.value ?? const <ServiceOrderWithClient>[];
    // Histórico: mais recente primeiro, por data/hora de cadastro.
    final epoch = DateTime.fromMillisecondsSinceEpoch(0);
    final mine = [
      for (final e in all)
        if (_matches(e.order)) e,
    ]..sort(
      (a, b) => (_createdAt(b.order) ?? epoch).compareTo(
        _createdAt(a.order) ?? epoch,
      ),
    );
    final loading = async.isLoading && async.value == null;

    const previewLimit = 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            loading ? 'Laudos' : 'Laudos (${mine.length})',
            style: theme.textTheme.titleSmall,
          ),
        ),
        const SizedBox(height: 8),
        if (mine.isEmpty && !loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Nenhum laudo relacionado.'),
          )
        else
          Column(
            children: [
              for (final e in mine.take(previewLimit))
                Card(
                  child: ListTile(
                    title: Text(_fmtDateTime(_createdAt(e.order))),
                    subtitle: Text(_statusReason(e.order)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () =>
                        context.push('/service-orders/${e.order.id}'),
                  ),
                ),
            ],
          ),
        if (mine.isNotEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => context.push('/service-orders?$_query'),
              child: Text('Ver todos (${mine.length})'),
            ),
          ),
      ],
    );
  }
}
