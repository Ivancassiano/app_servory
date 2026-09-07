import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/app_database.dart';
import '../../../core/widgets/child_list_section.dart';
import '../../locations/application/locations_provider.dart';
import '../application/equipments_provider.dart';

/// "Equipamentos" na tela do cliente — os equipamentos de todos os locais
/// deste cliente (dá pra chegar num equipamento sem abrir local por local).
/// Prévia curta + "Ver todos" pra lista filtrada.
class ClientEquipmentsSection extends ConsumerWidget {
  const ClientEquipmentsSection({super.key, required this.clientId});

  final String clientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final equipmentsAsync = ref.watch(equipmentListProvider);
    final theme = Theme.of(context);

    final locsById = {
      for (final l
          in ref.watch(locationListProvider).value ?? const <LocalLocation>[])
        l.id: l,
    };
    final all = equipmentsAsync.value ?? const <LocalEquipment>[];
    final mine =
        [
          for (final e in all)
            if (locsById[e.locationId]?.clientId == clientId) e,
        ]..sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );

    if (equipmentsAsync.hasError && equipmentsAsync.value == null) {
      return Text(
        'Não foi possível carregar os equipamentos.',
        style: TextStyle(color: theme.colorScheme.error),
      );
    }

    const previewLimit = 4;
    final loading = equipmentsAsync.isLoading && equipmentsAsync.value == null;

    return ChildListSection(
      title: 'Equipamentos',
      count: loading ? null : mine.length,
      emptyMessage: 'Nenhum equipamento para este cliente.',
      addLabel: 'Novo equipamento',
      onAdd: () => context.push('/equipments/new?clientId=$clientId'),
      seeAllLabel: mine.length > previewLimit
          ? 'Ver todos (${mine.length})'
          : null,
      onSeeAll: mine.length > previewLimit
          ? () => context.push('/equipments?clientId=$clientId')
          : null,
      children: [
        for (final e in mine.take(previewLimit))
          Card(
            child: ListTile(
              title: Text(e.name),
              subtitle: Text(locsById[e.locationId]?.name ?? '—'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/equipments/${e.id}'),
            ),
          ),
      ],
    );
  }
}
