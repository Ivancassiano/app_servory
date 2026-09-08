import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/app_database.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/active_status.dart';
import '../../../core/widgets/brand_app_bar.dart';
import '../../../core/widgets/searchable_list_view.dart';
import '../../clients/application/clients_provider.dart';
import '../application/locations_provider.dart';
import '../data/location_mapper.dart';

/// Lista de locais. Com `clientId` fica presa àquele cliente.
class LocationListScreen extends ConsumerStatefulWidget {
  const LocationListScreen({super.key, this.clientId});

  final String? clientId;

  @override
  ConsumerState<LocationListScreen> createState() => _LocationListScreenState();
}

class _LocationListScreenState extends ConsumerState<LocationListScreen> {
  ActiveFilter _status = ActiveFilter.ativos;

  @override
  Widget build(BuildContext context) {
    final clientId = widget.clientId;
    final async = ref.watch(locationListProvider);
    final clients = {
      for (final c in ref.watch(clientListProvider).value ?? const [])
        c.id: c.name,
    };
    final scopeName = clientId == null ? null : clients[clientId];
    final newQuery = clientId == null ? '' : '?clientId=$clientId';

    return Scaffold(
      appBar: brandAppBar(
        title: 'Locais',
        subtitle: scopeName,
        leading: clientId == null ? null : const BackButton(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/locations/new$newQuery'),
        icon: const Icon(Icons.add),
        label: const Text('Novo local'),
      ),
      body: SearchableListView<LocalLocation>(
        async: async,
        onRefresh: () => ref.read(locationRepositoryProvider).refresh(),
        hintText: 'Buscar por nome ou endereço',
        emptyMessage: 'Nenhum local cadastrado.',
        filterBar: ActiveFilterBar(
          value: _status,
          onChanged: (f) => setState(() => _status = f),
        ),
        extraFilter: (l) {
          if (clientId != null && l.clientId != clientId) return false;
          return _status.accepts(l.isActive);
        },
        searchText: (l) =>
            [l.name, clients[l.clientId] ?? '', locationAddressLine(l)].join(' '),
        itemBuilder: (context, l) {
          final addr = locationAddressLine(l);
          final title = l.name.isNotEmpty
              ? l.name
              : (addr.isNotEmpty ? addr : 'Local sem nome');
          final subtitle = [
            if (clientId == null && clients[l.clientId] != null)
              clients[l.clientId]!,
            if (l.name.isNotEmpty && addr.isNotEmpty) addr,
          ].join(' · ');
          return ListTile(
            title: Text(
              title,
              style: l.isActive
                  ? null
                  : const TextStyle(color: BrandColor.textTertiary),
            ),
            subtitle: subtitle.isEmpty ? null : Text(subtitle),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ActiveBadge(active: l.isActive),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: () => context.push('/locations/${l.id}'),
          );
        },
      ),
    );
  }
}
