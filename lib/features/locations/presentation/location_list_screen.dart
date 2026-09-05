import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../sync/application/sync_provider.dart';
import '../application/locations_provider.dart';

class LocationListScreen extends ConsumerWidget {
  const LocationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationsAsync = ref.watch(locationListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Locais')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(syncRunnerProvider.notifier).runSync(),
        child: locationsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Text(
              'Não foi possível carregar os locais.\n$error',
              textAlign: TextAlign.center,
            ),
          ),
          data: (locations) {
            if (locations.isEmpty) {
              return ListView(
                children: const [
                  Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'Nenhum local ainda. Puxe pra baixo para sincronizar.',
                      ),
                    ),
                  ),
                ],
              );
            }
            return ListView.separated(
              itemCount: locations.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final location = locations[index];
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
                  onTap: () => context.push('/locations/${location.id}'),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
