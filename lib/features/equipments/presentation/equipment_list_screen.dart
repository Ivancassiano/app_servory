import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/app_database.dart';
import '../../../core/widgets/brand_app_bar.dart';
import '../../../core/widgets/client_filter_bar.dart';
import '../../../core/widgets/searchable_list_view.dart';
import '../../clients/application/clients_provider.dart';
import '../../locations/application/locations_provider.dart';
import '../application/equipments_provider.dart';

class EquipmentListScreen extends ConsumerWidget {
  const EquipmentListScreen({super.key, this.clientId});

  /// Quando setado, mostra só os equipamentos dos locais deste cliente.
  final String? clientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(equipmentListProvider);
    final locsById = {
      for (final l
          in ref.watch(locationListProvider).value ?? const <LocalLocation>[])
        l.id: l,
    };
    final clientsById = {
      for (final c
          in ref.watch(clientListProvider).value ?? const <LocalClient>[])
        c.id: c.name,
    };

    String? clientOf(LocalEquipment e) => locsById[e.locationId]?.clientId;
    bool mine(LocalEquipment e) => clientId == null || clientOf(e) == clientId;
    final total = async.value?.where(mine).length;

    return Scaffold(
      appBar: brandAppBar(
        title: 'Equipamentos',
        count: total == null
            ? null
            : '$total ${total == 1 ? 'item' : 'itens'}',
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
        loadAllOnInit: clientId != null,
        extraFilter: clientId == null ? null : mine,
        filterBar: clientId == null
            ? null
            : ClientFilterBar(
                label: clientsById[clientId] ?? 'Cliente',
                onClear: () => context.go('/equipments'),
              ),
        onRefresh: () => ref.read(equipmentRepositoryProvider).refresh(),
        hintText: 'Buscar equipamento, local ou cliente',
        emptyMessage:
            'Nenhum equipamento ainda. Puxe pra baixo para sincronizar.',
        errorMessage: 'Não foi possível carregar os equipamentos.',
        searchText: (e) {
          final loc = locsById[e.locationId];
          final client = loc == null ? '' : clientsById[loc.clientId] ?? '';
          return '${e.name} ${e.brand} ${e.model} ${e.serialNumber ?? ''} '
              '${loc?.name ?? ''} $client';
        },
        itemBuilder: (context, equipment) {
          final loc = locsById[equipment.locationId];
          final client = loc == null ? '' : clientsById[loc.clientId] ?? '';
          final origin = [
            if (client.isNotEmpty) client,
            if (loc != null && loc.name.isNotEmpty) loc.name,
          ].join(' · ');
          final spec = [
            equipment.brand,
            equipment.model,
          ].where((s) => s.isNotEmpty).join(' ');
          return ListTile(
            isThreeLine: origin.isNotEmpty && spec.isNotEmpty,
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
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(origin.isNotEmpty ? origin : '—'),
                if (spec.isNotEmpty)
                  Text(spec, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
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
        onPressed: () => context.push(
          clientId == null
              ? '/equipments/new'
              : '/equipments/new?clientId=$clientId',
        ),
        icon: const Icon(Icons.add),
        label: const Text('Novo equipamento'),
      ),
    );
  }
}
