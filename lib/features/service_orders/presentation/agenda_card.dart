import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/agenda.dart';
import '../application/service_orders_provider.dart';

/// Painel "Agenda" da home: ordens agendadas (atrasadas / hoje / próximos
/// dias). Some quando não há nada agendado.
class AgendaCard extends ConsumerWidget {
  const AgendaCard({super.key, this.maxItems = 6});

  final int maxItems;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(serviceOrderListProvider).value;
    if (orders == null) return const SizedBox.shrink();

    final agenda = buildAgenda(orders, now: DateTime.now());
    if (agenda.isEmpty) return const SizedBox.shrink();

    final overdue =
        agenda.where((a) => a.bucket == AgendaBucket.overdue).length;
    final today = agenda.where((a) => a.bucket == AgendaBucket.today).length;
    final shown = agenda.take(maxItems).toList();

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.event_note_outlined),
            title: const Text('Agenda'),
            subtitle: Text(_summary(overdue, today, agenda.length)),
            trailing: agenda.length > shown.length
                ? TextButton(
                    onPressed: () => context.push('/service-orders'),
                    child: Text('+${agenda.length - shown.length}'),
                  )
                : null,
          ),
          const Divider(height: 1),
          for (final item in shown) _AgendaTile(item: item),
        ],
      ),
    );
  }

  static String _summary(int overdue, int today, int total) {
    final parts = <String>[
      if (overdue > 0) '$overdue atrasada${overdue > 1 ? 's' : ''}',
      if (today > 0) '$today hoje',
    ];
    if (parts.isEmpty) {
      return '$total agendada${total > 1 ? 's' : ''} nos próximos dias';
    }
    return parts.join(' · ');
  }
}

class _AgendaTile extends StatelessWidget {
  const _AgendaTile({required this.item});

  final AgendaItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (item.bucket) {
      AgendaBucket.overdue => scheme.error,
      AgendaBucket.today => Colors.orange.shade700,
      AgendaBucket.upcoming => scheme.outline,
    };
    final reason = item.order.reason;

    return ListTile(
      dense: true,
      leading: Icon(Icons.circle, size: 12, color: color),
      title: Text(item.entry.clientName, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${agendaDateLabel(item.scheduledLocal, DateTime.now())}'
        '${reason.isNotEmpty ? ' · $reason' : ''}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () => context.push('/service-orders/${item.order.id}'),
    );
  }
}
