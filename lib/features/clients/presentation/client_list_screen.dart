import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../sync/application/sync_provider.dart';
import '../application/clients_provider.dart';

class ClientListScreen extends ConsumerWidget {
  const ClientListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientsAsync = ref.watch(clientListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Clientes')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(syncRunnerProvider.notifier).runSync(),
        child: clientsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Text(
              'Não foi possível carregar os clientes.\n$error',
              textAlign: TextAlign.center,
            ),
          ),
          data: (clients) {
            if (clients.isEmpty) {
              return ListView(
                children: const [
                  Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'Nenhum cliente ainda. Puxe pra baixo para sincronizar.',
                      ),
                    ),
                  ),
                ],
              );
            }
            return ListView.separated(
              itemCount: clients.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final client = clients[index];
                return ListTile(
                  title: Text(client.name),
                  subtitle: Text(
                    client.phone.isNotEmpty
                        ? client.phone
                        : (client.email.isNotEmpty ? client.email : '—'),
                  ),
                  trailing: switch (client.syncStatus) {
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
                  onTap: () => context.push('/clients/${client.id}'),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/clients/new'),
        tooltip: 'Novo cliente',
        child: const Icon(Icons.add),
      ),
    );
  }
}
