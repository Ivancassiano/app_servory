import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/app_database.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/brand_app_bar.dart';
import '../../../core/widgets/searchable_list_view.dart';
import '../../clients/application/clients_provider.dart';
import '../application/locations_provider.dart';
import '../data/location_mapper.dart';

/// Filtro rápido de situação do local. `ativos` é o padrão.
enum _StatusFilter { ativos, inativos, todos }

/// Lista de locais. Com `clientId` fica presa àquele cliente.
class LocationListScreen extends ConsumerStatefulWidget {
  const LocationListScreen({super.key, this.clientId});

  final String? clientId;

  @override
  ConsumerState<LocationListScreen> createState() => _LocationListScreenState();
}

class _LocationListScreenState extends ConsumerState<LocationListScreen> {
  _StatusFilter _status = _StatusFilter.ativos;

  bool _matchesStatus(LocalLocation l) => switch (_status) {
    _StatusFilter.ativos => l.isActive,
    _StatusFilter.inativos => !l.isActive,
    _StatusFilter.todos => true,
  };

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
        filterBar: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              for (final f in _StatusFilter.values) ...[
                if (f != _StatusFilter.values.first) const SizedBox(width: 8),
                _FilterChip(
                  label: switch (f) {
                    _StatusFilter.ativos => 'Ativos',
                    _StatusFilter.inativos => 'Inativos',
                    _StatusFilter.todos => 'Todos',
                  },
                  selected: _status == f,
                  onTap: () => setState(() => _status = f),
                ),
              ],
            ],
          ),
        ),
        extraFilter: (l) {
          if (clientId != null && l.clientId != clientId) return false;
          return _matchesStatus(l);
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
                _StatusBadge(active: l.isActive),
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

/// Chip do filtro rápido (mesma pegada de `service_order_list_screen`).
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? BrandColor.ink : BrandColor.surface,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? BrandColor.ink : BrandColor.border,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'IBM Plex Mono',
              fontSize: 11,
              color: selected ? Colors.white : BrandColor.ink,
            ),
          ),
        ),
      ),
    );
  }
}

/// Selo compacto "Ativo/Inativo" ao lado de cada local.
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(
          color: active ? BrandColor.border : BrandColor.errorBar,
        ),
        color: active ? BrandColor.surface : BrandColor.errorBg,
      ),
      child: Text(
        active ? 'Ativo' : 'Inativo',
        style: TextStyle(
          fontFamily: 'IBM Plex Mono',
          fontSize: 10,
          color: active ? BrandColor.textTertiary : BrandColor.errorText,
        ),
      ),
    );
  }
}
