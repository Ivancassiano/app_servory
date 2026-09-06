import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/app_database.dart';
import '../../../core/widgets/searchable_list_view.dart';
import '../application/locations_provider.dart';

class LocationListScreen extends ConsumerWidget {
  const LocationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Locais')),
      body: SearchableListView<LocalLocation>(
        async: ref.watch(locationListProvider),
        onRefresh: () => ref.read(locationRepositoryProvider).refresh(),
        hintText: 'Buscar local',
        emptyMessage: 'Nenhum local ainda. Puxe pra baixo para sincronizar.',
        errorMessage: 'Não foi possível carregar os locais.',
        searchText: (l) =>
            '${l.name} ${l.city} ${l.state} ${l.district} ${l.street} ${l.contactPerson}',
        itemBuilder: (context, location) {
          final address = [
            location.city,
            location.state,
          ].where((s) => s.isNotEmpty).join(' - ');
          return ListTile(
            title: Text(location.name),
            subtitle: Text(
              address.isNotEmpty
                  ? address
                  : (location.contactPerson.isNotEmpty
                        ? location.contactPerson
                        : '—'),
            ),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/locations/new'),
        tooltip: 'Novo local',
        child: const Icon(Icons.add),
      ),
    );
  }
}
