import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../sync/application/sync_provider.dart';
import '../application/equipments_provider.dart';

class EquipmentListScreen extends ConsumerWidget {
  const EquipmentListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final equipmentsAsync = ref.watch(equipmentListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Equipamentos')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(syncRunnerProvider.notifier).runSync(),
        child: equipmentsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Text(
              'Não foi possível carregar os equipamentos.\n$error',
              textAlign: TextAlign.center,
            ),
          ),
          data: (equipments) {
            if (equipments.isEmpty) {
              return ListView(
                children: const [
                  Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'Nenhum equipamento ainda. Puxe pra baixo para sincronizar.',
                      ),
                    ),
                  ),
                ],
              );
            }
            return ListView.separated(
              itemCount: equipments.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final equipment = equipments[index];
                final subtitle = [
                  equipment.brand,
                  equipment.model,
                ].where((s) => s.isNotEmpty).join(' ');
                return ListTile(
                  leading: switch (equipment.syncStatus) {
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
                  title: Text(equipment.name),
                  subtitle: Text(subtitle.isNotEmpty ? subtitle : '—'),
                  trailing:
                      (equipment.serialNumber != null &&
                          equipment.serialNumber!.isNotEmpty)
                      ? Text(
                          'S/N ${equipment.serialNumber}',
                          style: Theme.of(context).textTheme.bodySmall,
                        )
                      : null,
                  onTap: () => context.push('/equipments/${equipment.id}'),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
