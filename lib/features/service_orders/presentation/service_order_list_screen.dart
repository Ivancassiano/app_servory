import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/searchable_list_view.dart';
import '../../attachments/application/pending_uploads.dart';
import '../application/service_orders_provider.dart';

const _statusLabels = {
  'draft': 'Rascunho',
  'open': 'Aberta',
  'in_progress': 'Em andamento',
  'completed': 'Concluída',
};

class ServiceOrderListScreen extends ConsumerStatefulWidget {
  const ServiceOrderListScreen({super.key});

  @override
  ConsumerState<ServiceOrderListScreen> createState() =>
      _ServiceOrderListScreenState();
}

class _ServiceOrderListScreenState
    extends ConsumerState<ServiceOrderListScreen> {
  String? _status;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ordens de serviço'),
        actions: [
          IconButton(
            tooltip: 'Tipos de ordem',
            icon: const Icon(Icons.category_outlined),
            onPressed: () => context.push('/type-catalog?kind=service-order'),
          ),
        ],
      ),
      body: SearchableListView<ServiceOrderWithClient>(
        async: ref.watch(serviceOrderListProvider),
        onRefresh: () async {
          await ref.read(serviceOrderRepositoryProvider).refresh();
          await drainPendingUploads(ref);
        },
        hintText: 'Buscar por cliente ou motivo',
        emptyMessage: 'Nenhuma ordem ainda. Puxe pra baixo para sincronizar.',
        errorMessage: 'Não foi possível carregar as ordens.',
        searchText: (e) => '${e.clientName} ${e.order.reason}',
        extraFilter: _status == null
            ? null
            : (e) => e.order.status == _status,
        filterBar: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              ChoiceChip(
                label: const Text('Todas'),
                selected: _status == null,
                onSelected: (_) => setState(() => _status = null),
              ),
              for (final entry in _statusLabels.entries) ...[
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(entry.value),
                  selected: _status == entry.key,
                  onSelected: (_) => setState(
                    () => _status = _status == entry.key ? null : entry.key,
                  ),
                ),
              ],
            ],
          ),
        ),
        itemBuilder: (context, entry) {
          final order = entry.order;
          return ListTile(
            title: Text(entry.clientName),
            subtitle: Text(
              '${_statusLabels[order.status] ?? order.status}'
              '${order.reason.isNotEmpty ? ' · ${order.reason}' : ''}',
            ),
            trailing: switch (order.syncStatus) {
              'pending' => const Icon(Icons.cloud_upload_outlined, size: 20),
              'conflict' => Icon(
                Icons.warning_amber,
                size: 20,
                color: Theme.of(context).colorScheme.error,
              ),
              _ => null,
            },
            onTap: () => context.push('/service-orders/${order.id}'),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/service-orders/new'),
        tooltip: 'Nova ordem',
        child: const Icon(Icons.add),
      ),
    );
  }
}
