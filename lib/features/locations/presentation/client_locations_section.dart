import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/child_list_section.dart';
import '../application/locations_provider.dart';
import '../data/location_mapper.dart';

/// Bloco "locais deste cliente" na tela do cliente — prévia + "Ver todos".
class ClientLocationsSection extends ConsumerWidget {
  const ClientLocationsSection({super.key, required this.clientId});

  final String clientId;

  static const _previewLimit = 4;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locations = [...ref.watch(locationsByClientProvider(clientId))]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final preview = locations.take(_previewLimit).toList();
    final hasMore = locations.length > _previewLimit;

    return ChildListSection(
      title: 'Locais',
      count: locations.length,
      emptyMessage: 'Nenhum local cadastrado para este cliente.',
      addLabel: 'Novo local',
      onAdd: () => context.push('/locations/new?clientId=$clientId'),
      seeAllLabel: hasMore ? 'Ver todos' : null,
      onSeeAll: hasMore
          ? () => context.push('/locations?clientId=$clientId')
          : null,
      children: [
        for (final l in preview)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(l.name.isNotEmpty ? l.name : 'Local sem nome'),
            subtitle: locationAddressLine(l).isEmpty
                ? null
                : Text(locationAddressLine(l)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/locations/${l.id}'),
          ),
      ],
    );
  }
}
