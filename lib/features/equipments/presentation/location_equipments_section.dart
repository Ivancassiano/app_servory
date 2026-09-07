import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/child_list_section.dart';
import '../application/equipments_provider.dart';

/// "Equipamentos" na tela do local — os equipamentos deste local + atalho
/// para criar um já com o local fixo.
class LocationEquipmentsSection extends ConsumerWidget {
  const LocationEquipmentsSection({super.key, required this.locationId});

  final String locationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(equipmentListProvider);
    final theme = Theme.of(context);

    final all = async.value ?? const [];
    final mine = [
      for (final e in all)
        if (e.locationId == locationId) e,
    ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    if (async.hasError && async.value == null) {
      return Text(
        'Não foi possível carregar os equipamentos.',
        style: TextStyle(color: theme.colorScheme.error),
      );
    }

    return ChildListSection(
      title: 'Equipamentos',
      count: async.isLoading && async.value == null ? null : mine.length,
      emptyMessage: 'Nenhum equipamento neste local.',
      addLabel: 'Novo equipamento',
      onAdd: () => context.push('/equipments/new?locationId=$locationId'),
      children: [
        for (final e in mine)
          Card(
            child: ListTile(
              title: Text(e.name),
              subtitle: Text(_subtitle(e.brand, e.model)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/equipments/${e.id}'),
            ),
          ),
      ],
    );
  }

  static String _subtitle(String brand, String model) {
    final s = [brand, model].where((v) => v.isNotEmpty).join(' ');
    return s.isEmpty ? '—' : s;
  }
}
