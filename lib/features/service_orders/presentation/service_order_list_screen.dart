import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../attachments/application/pending_uploads.dart';
import '../application/service_orders_provider.dart';

const _statusLabels = {
  'draft': 'Rascunho',
  'open': 'Aberta',
  'in_progress': 'Em andamento',
  'completed': 'Concluída',
};

class ServiceOrderListScreen extends ConsumerWidget {
  const ServiceOrderListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(serviceOrderListProvider);

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
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(serviceOrderRepositoryProvider).refresh();
          await drainPendingUploads(ref);
        },
        child: ordersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Text(
              'Não foi possível carregar as ordens.\n$error',
              textAlign: TextAlign.center,
            ),
          ),
          data: (orders) {
            if (orders.isEmpty) {
              return ListView(
                children: const [
                  Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'Nenhuma ordem ainda. Puxe pra baixo para sincronizar.',
                      ),
                    ),
                  ),
                ],
              );
            }
            return ListView.separated(
              itemCount: orders.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final entry = orders[index];
                final order = entry.order;
                return ListTile(
                  title: Text(entry.clientName),
                  subtitle: Text(
                    '${_statusLabels[order.status] ?? order.status}'
                    '${order.reason.isNotEmpty ? ' · ${order.reason}' : ''}',
                  ),
                  trailing: switch (order.syncStatus) {
                    'pending' => const Icon(
                      Icons.cloud_upload_outlined,
                      size: 20,
                    ),
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
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/service-orders/new'),
        tooltip: 'Nova ordem',
        child: const Icon(Icons.add),
      ),
    );
  }
}
