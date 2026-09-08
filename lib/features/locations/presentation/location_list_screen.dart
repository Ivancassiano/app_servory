import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/app_database.dart';
import '../../../core/widgets/brand_app_bar.dart';
import '../../../core/widgets/searchable_list_view.dart';
import '../../clients/application/clients_provider.dart';
import '../application/locations_provider.dart';
import '../data/location_mapper.dart';

/// Lista de locais. Com `clientId` fica presa àquele cliente.
class LocationListScreen extends ConsumerWidget {
  const LocationListScreen({super.key, this.clientId});

  final String? clientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(locationListProvider);
    final clients = {
      for (final c in ref.watch(clientListProvider).value ?? const [])
        c.id: c.name,
    };
    final scopeName = clientId == null ? null : clients[clientId];
    final newQuery = clientId == null ? '' : '?clientId=$clientId';

    return Scaffold(
      appBar: brandAppBar(
        title: 'Locais',
        subtitle: scopeName,
        leading: clientId == null ? null : const BackButton(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/locations/new$newQuery'),
        icon: const Icon(Icons.add),
        label: const Text('Novo local'),
      ),
      body: SearchableListView<LocalLocation>(
        async: async,
        onRefresh: () => ref.read(locationRepositoryProvider).refresh(),
        hintText: 'Buscar por nome ou endereço',
        emptyMessage: 'Nenhum local cadastrado.',
        extraFilter: clientId == null ? null : (l) => l.clientId == clientId,
        searchText: (l) =>
            [l.name, clients[l.clientId] ?? '', locationAddressLine(l)].join(' '),
        itemBuilder: (context, l) {
          final addr = locationAddressLine(l);
          final title = l.name.isNotEmpty
              ? l.name
              : (addr.isNotEmpty ? addr : 'Local sem nome');
          final subtitle = [
            if (clientId == null && clients[l.clientId] != null)
              clients[l.clientId]!,
            if (l.name.isNotEmpty && addr.isNotEmpty) addr,
          ].join(' · ');
          return ListTile(
            title: Text(title),
            subtitle: subtitle.isEmpty ? null : Text(subtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/locations/${l.id}'),
          );
        },
      ),
    );
  }
}
