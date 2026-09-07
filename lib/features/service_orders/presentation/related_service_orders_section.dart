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
    final mine = [
      for (final e in all)
        if (_matches(e.order)) e,
    ]..sort((a, b) => b.order.id.compareTo(a.order.id));
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
                    title: Text(
                      _statusLabels[e.order.status] ?? e.order.status,
                    ),
                    subtitle: Text(
                      e.order.reason.isEmpty ? '—' : e.order.reason,
                    ),
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
