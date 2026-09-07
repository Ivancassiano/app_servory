import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/app_database.dart';
import '../../../core/widgets/brand_app_bar.dart';
import '../../../core/widgets/searchable_list_view.dart';
import '../application/equipments_provider.dart';

class EquipmentListScreen extends ConsumerWidget {
  const EquipmentListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(equipmentListProvider);
    final total = async.value?.length;
    return Scaffold(
      appBar: brandAppBar(
        title: 'Equipamentos',
        count: total == null ? null : '$total ${total == 1 ? 'item' : 'itens'}',
        actions: [
          IconButton(
            tooltip: 'Tipos de equipamento',
            icon: const Icon(Icons.category_outlined),
            onPressed: () => context.push('/type-catalog?kind=equipment'),
          ),
        ],
      ),
      body: SearchableListView<LocalEquipment>(
        async: async,
        paging: ref.watch(equipmentListPagingProvider),
        onRefresh: () => ref.read(equipmentRepositoryProvider).refresh(),
        hintText: 'Buscar equipamento',
        emptyMessage:
            'Nenhum equipamento ainda. Puxe pra baixo para sincronizar.',
        errorMessage: 'Não foi possível carregar os equipamentos.',
        searchText: (e) =>
            '${e.name} ${e.brand} ${e.model} ${e.serialNumber ?? ''}',
        itemBuilder: (context, equipment) {
          final subtitle = [
            equipment.brand,
            equipment.model,
          ].where((s) => s.isNotEmpty).join(' ');
          return ListTile(
            leading: switch (equipment.syncStatus) {
              'pending' => const Icon(Icons.cloud_upload_outlined, size: 20),
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/equipments/new'),
        icon: const Icon(Icons.add),
        label: const Text('Novo equipamento'),
      ),
    );
  }
}
