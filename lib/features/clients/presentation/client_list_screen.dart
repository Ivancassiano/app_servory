import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/app_database.dart';
import '../../../core/widgets/searchable_list_view.dart';
import '../application/clients_provider.dart';

class ClientListScreen extends ConsumerWidget {
  const ClientListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clientes')),
      body: SearchableListView<LocalClient>(
        async: ref.watch(clientListProvider),
        onRefresh: () => ref.read(clientRepositoryProvider).refresh(),
        hintText: 'Buscar cliente',
        emptyMessage: 'Nenhum cliente ainda. Puxe pra baixo para sincronizar.',
        errorMessage: 'Não foi possível carregar os clientes.',
        searchText: (c) => '${c.name} ${c.phone} ${c.email}',
        itemBuilder: (context, client) => ListTile(
          title: Text(client.name),
          subtitle: Text(
            client.phone.isNotEmpty
                ? client.phone
                : (client.email.isNotEmpty ? client.email : '—'),
          ),
          trailing: switch (client.syncStatus) {
            'pending' => const Icon(Icons.cloud_upload_outlined, size: 20),
            'conflict' => Icon(
              Icons.warning_amber,
              size: 20,
              color: Theme.of(context).colorScheme.error,
            ),
            _ => null,
          },
          onTap: () => context.push('/clients/${client.id}'),
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
