import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/child_list_section.dart';
import '../application/locations_provider.dart';

/// "Locais" na tela do cliente — os locais deste cliente + atalho para criar
/// um já com o cliente fixo.
class ClientLocationsSection extends ConsumerWidget {
  const ClientLocationsSection({super.key, required this.clientId});

  final String clientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(locationListProvider);
    final theme = Theme.of(context);

    final all = async.value ?? const [];
    final mine = [
      for (final l in all)
        if (l.clientId == clientId) l,
    ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    if (async.hasError && async.value == null) {
      return Text(
        'Não foi possível carregar os locais.',
        style: TextStyle(color: theme.colorScheme.error),
      );
    }

    const previewLimit = 4;
    final preview = mine.take(previewLimit).toList();

    return ChildListSection(
      title: 'Locais',
      count: async.isLoading && async.value == null ? null : mine.length,
      emptyMessage: 'Nenhum local para este cliente.',
      addLabel: 'Novo local',
      onAdd: () => context.push('/locations/new?clientId=$clientId'),
      seeAllLabel: mine.length > previewLimit
          ? 'Ver todos (${mine.length})'
          : null,
      onSeeAll: mine.length > previewLimit
          ? () => context.push('/locations?clientId=$clientId')
          : null,
      children: [
        for (final l in preview)
          Card(
            child: ListTile(
              title: Text(l.name),
              subtitle: Text(_subtitle(l.city, l.state, l.contactPerson)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/locations/${l.id}'),
            ),
          ),
      ],
    );
  }

  static String _subtitle(String city, String state, String contact) {
    final place = [city, state].where((s) => s.isNotEmpty).join(' - ');
    if (place.isNotEmpty) return place;
    return contact.isNotEmpty ? contact : '—';
  }
}
