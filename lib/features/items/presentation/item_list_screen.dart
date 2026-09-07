import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/app_database.dart';
import '../../../core/widgets/brand_app_bar.dart';
import '../../../core/widgets/searchable_list_view.dart';
import '../../clients/application/clients_provider.dart';
import '../application/items_provider.dart';

/// Lista de itens (a fusão local+equipamento). Com `clientId` fica presa àquele
/// cliente e mostra o nome no cabeçalho.
class ItemListScreen extends ConsumerWidget {
  const ItemListScreen({super.key, this.clientId});

  final String? clientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(itemListProvider);
    final clients = {
      for (final c in ref.watch(clientListProvider).value ?? const [])
        c.id: c.name,
    };
    final types = {
      for (final t in ref.watch(itemTypeListProvider).value ?? const [])
        t.id: t.name,
    };
    final scopeName = clientId == null ? null : clients[clientId];

    return Scaffold(
      appBar: brandAppBar(
        title: 'Itens',
        subtitle: scopeName,
        leading: clientId == null ? null : const BackButton(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(
          clientId == null ? '/items/new' : '/items/new?clientId=$clientId',
        ),
        icon: const Icon(Icons.add),
        label: const Text('Novo item'),
      ),
      body: SearchableListView<LocalItem>(
        async: async,
        onRefresh: () => ref.read(itemRepositoryProvider).refresh(),
        hintText: 'Buscar por nome, cliente ou série',
        emptyMessage: 'Nenhum item cadastrado.',
        extraFilter: clientId == null ? null : (i) => i.clientId == clientId,
        searchText: (i) => [
          i.name,
          clients[i.clientId] ?? '',
          types[i.itemTypeId] ?? '',
          i.serialNumber ?? '',
          i.city,
        ].join(' '),
        itemBuilder: (context, i) {
          final subtitle = [
            if (clientId == null && clients[i.clientId] != null)
              clients[i.clientId]!,
            if (types[i.itemTypeId] != null) types[i.itemTypeId]!,
            if (i.parentItemId != null) 'subitem',
          ].join(' · ');
          return ListTile(
            title: Text(i.name),
            subtitle: subtitle.isEmpty ? null : Text(subtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/items/${i.id}'),
          );
        },
      ),
    );
  }
}
