import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/app_database.dart';
import '../../../core/widgets/brand_app_bar.dart';
import '../../../core/widgets/client_filter_bar.dart';
import '../../../core/widgets/searchable_list_view.dart';
import '../../clients/application/clients_provider.dart';
import '../application/locations_provider.dart';

class LocationListScreen extends ConsumerWidget {
  const LocationListScreen({super.key, this.clientId});

  /// Quando setado, a lista mostra só os locais deste cliente (aberta pela
  /// tela do cliente). O chip no topo limpa o filtro.
  final String? clientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(locationListProvider);
    final clientsById = {
      for (final c in ref.watch(clientListProvider).value ?? const <LocalClient>[])
        c.id: c.name,
    };

    bool mine(LocalLocation l) => clientId == null || l.clientId == clientId;
    final total = async.value?.where(mine).length;

    return Scaffold(
      appBar: brandAppBar(
        title: 'Locais',
        count: total == null ? null : '$total ${total == 1 ? 'local' : 'locais'}',
      ),
      body: SearchableListView<LocalLocation>(
        async: async,
        paging: ref.watch(locationListPagingProvider),
        loadAllOnInit: clientId != null,
        extraFilter: clientId == null ? null : mine,
        filterBar: clientId == null
            ? null
            : ClientFilterBar(
                label: clientsById[clientId] ?? 'Cliente',
                onClear: () => context.go('/locations'),
              ),
        onRefresh: () => ref.read(locationRepositoryProvider).refresh(),
        hintText: 'Buscar local ou cliente',
        emptyMessage: 'Nenhum local ainda. Puxe pra baixo para sincronizar.',
        errorMessage: 'Não foi possível carregar os locais.',
        searchText: (l) => '${l.name} ${clientsById[l.clientId] ?? ''} '
            '${l.city} ${l.state} ${l.district} ${l.street} ${l.contactPerson}',
        itemBuilder: (context, location) {
          final place = [
            location.city,
            location.state,
          ].where((s) => s.isNotEmpty).join(' - ');
          final clientName = clientsById[location.clientId] ?? '';
          final subtitle = [
            if (clientName.isNotEmpty) clientName,
            if (place.isNotEmpty)
              place
            else if (location.contactPerson.isNotEmpty)
              location.contactPerson,
          ].join(' · ');
          return ListTile(
            title: Text(location.name),
            subtitle: Text(subtitle.isNotEmpty ? subtitle : '—'),
            trailing: switch (location.syncStatus) {
              'pending' => const Icon(Icons.cloud_upload_outlined, size: 20),
              'conflict' => Icon(
                Icons.warning_amber,
                size: 20,
                color: Theme.of(context).colorScheme.error,
              ),
              _ => null,
            },
            onTap: () => context.push('/locations/${location.id}'),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(
          clientId == null
              ? '/locations/new'
              : '/locations/new?clientId=$clientId',
        ),
        icon: const Icon(Icons.add),
        label: const Text('Novo local'),
      ),
    );
  }
}
