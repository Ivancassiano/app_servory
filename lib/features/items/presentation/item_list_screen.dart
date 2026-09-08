import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/app_database.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/active_status.dart';
import '../../../core/widgets/brand_app_bar.dart';
import '../../../core/widgets/searchable_list_view.dart';
import '../../clients/application/clients_provider.dart';
import '../../locations/application/locations_provider.dart';
import '../application/items_provider.dart';

/// Lista de itens. Com `clientId` ou `locationId` fica presa àquele escopo e
/// mostra o nome no cabeçalho.
class ItemListScreen extends ConsumerStatefulWidget {
  const ItemListScreen({super.key, this.clientId, this.locationId});

  final String? clientId;
  final String? locationId;

  @override
  ConsumerState<ItemListScreen> createState() => _ItemListScreenState();
}

class _ItemListScreenState extends ConsumerState<ItemListScreen> {
  ActiveFilter _status = ActiveFilter.ativos;

  @override
  Widget build(BuildContext context) {
    final clientId = widget.clientId;
    final locationId = widget.locationId;
    final async = ref.watch(itemListProvider);
    final clients = {
      for (final c in ref.watch(clientListProvider).value ?? const [])
        c.id: c.name,
    };
    final types = {
      for (final t in ref.watch(itemTypeListProvider).value ?? const [])
        t.id: t.name,
    };
    final locations = {
      for (final l in ref.watch(locationListProvider).value ?? const [])
        l.id: l.name.isNotEmpty ? l.name : l.city,
    };
    final scopeName = clientId != null
        ? clients[clientId]
        : (locationId != null ? locations[locationId] : null);
    final newQuery = clientId != null
        ? '?clientId=$clientId'
        : (locationId != null ? '?locationId=$locationId' : '');

    return Scaffold(
      appBar: brandAppBar(
        title: 'Itens',
        subtitle: scopeName,
        leading: (clientId == null && locationId == null)
            ? null
            : const BackButton(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/items/new$newQuery'),
        icon: const Icon(Icons.add),
        label: const Text('Novo item'),
      ),
      body: SearchableListView<LocalItem>(
        async: async,
        onRefresh: () => ref.read(itemRepositoryProvider).refresh(),
        hintText: 'Buscar por nome, cliente ou série',
        emptyMessage: 'Nenhum item cadastrado.',
        filterBar: ActiveFilterBar(
          value: _status,
          onChanged: (f) => setState(() => _status = f),
        ),
        extraFilter: (i) {
          if (clientId != null && i.clientId != clientId) return false;
          if (locationId != null && i.locationId != locationId) return false;
          return _status.accepts(i.isActive);
        },
        searchText: (i) => [
          i.name,
          clients[i.clientId] ?? '',
          types[i.itemTypeId] ?? '',
          i.serialNumber ?? '',
          locations[i.locationId] ?? '',
        ].join(' '),
        itemBuilder: (context, i) {
          final subtitle = [
            if (clientId == null && clients[i.clientId] != null)
              clients[i.clientId]!,
            if (types[i.itemTypeId] != null) types[i.itemTypeId]!,
            if (locationId == null && (locations[i.locationId] ?? '').isNotEmpty)
              locations[i.locationId]!,
          ].join(' · ');
          return ListTile(
            title: Text(
              i.name,
              style: i.isActive
                  ? null
                  : const TextStyle(color: BrandColor.textTertiary),
            ),
            subtitle: subtitle.isEmpty ? null : Text(subtitle),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ActiveBadge(active: i.isActive),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: () => context.push('/items/${i.id}'),
          );
        },
      ),
    );
  }
}
