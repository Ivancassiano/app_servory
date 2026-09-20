import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../clients/application/clients_provider.dart';
import '../../contacts/data/contact_repository.dart';
import '../../items/application/items_provider.dart';
import '../../locations/application/locations_provider.dart';
import '../../locations/data/location_mapper.dart';
import '../data/task_mapper.dart';
import 'task_target_picker_screen.dart';

/// Frame "Alvos" da tarefa: locais e itens. Cliente, local e item são
/// independentes entre si (ADR-0026/ADR-0027) — um alvo pode ter cliente
/// diferente do da tarefa (ou nenhum), então cada local/item aqui é agrupado
/// pelo *seu próprio* cliente, não pelo `clientId` da tarefa: um frame por
/// cliente reúne os locais/itens dele; sem cliente, cada local/item vira o
/// seu próprio frame. Um item vinculado a um local aparece aninhado sob ele
/// (sempre visível); endereço + contatos do cliente do local (quando há um)
/// ficam atrás de um botão "Ver endereço e contato".
class TaskTargetsField extends ConsumerWidget {
  const TaskTargetsField({
    super.key,
    required this.clientId,
    required this.targets,
    required this.onChanged,
    this.readOnly = false,
  });

  /// Cliente da tarefa. Quando presente, restringe o seletor a locais/itens
  /// dele (regra do servidor: com cliente, todo alvo precisa ser dele —
  /// `resolveRefs`); quando nulo, o seletor busca a organização inteira.
  final String? clientId;
  final List<TaskTargetInput> targets;
  final ValueChanged<List<TaskTargetInput>> onChanged;
  final bool readOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final locById = <String, LocalLocation>{
      for (final l in ref.watch(locationListProvider).value ?? const [])
        l.id: l,
    };
    final itemById = <String, LocalItem>{
      for (final i in ref.watch(itemListProvider).value ?? const []) i.id: i,
    };
    final clientNameById = <String, String>{
      for (final c in ref.watch(clientListProvider).value ?? const [])
        c.id: c.name,
    };

    // Agrupa: locationId -> itens; e itens soltos (sem local).
    final byLocation = <String, List<String>>{}; // locId -> [itemId]
    final looseItems = <String>[];
    for (final t in targets) {
      if (t.locationId != null) {
        byLocation.putIfAbsent(t.locationId!, () => []);
        if (t.itemId != null) byLocation[t.locationId!]!.add(t.itemId!);
      } else if (t.itemId != null) {
        looseItems.add(t.itemId!);
      }
    }
    // um local só entra se tiver uma linha "só local" (bare) ou algum item
    final standaloneLocations = targets
        .where((t) => t.locationId != null && t.itemId == null)
        .map((t) => t.locationId!)
        .toSet();
    final locationsToShow = {...standaloneLocations, ...byLocation.keys};

    void remove(bool Function(TaskTargetInput) test) {
      onChanged([
        for (final t in targets)
          if (!test(t)) t,
      ]);
    }

    Widget locationGroup(String locId) => _LocationGroup(
      location: locById[locId],
      readOnly: readOnly,
      itemNames: [
        for (final itemId in byLocation[locId] ?? const [])
          (id: itemId, name: itemById[itemId]?.name ?? 'Item'),
      ],
      onRemoveLocation: () => remove((t) => t.locationId == locId),
      onRemoveItem: (itemId) =>
          remove((t) => t.locationId == locId && t.itemId == itemId),
    );

    Widget looseItemTile(String itemId) => Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: ListTile(
        dense: true,
        leading: const Icon(Icons.inventory_2_outlined, size: 20),
        title: Text(itemById[itemId]?.name ?? 'Item'),
        subtitle: const Text('Sem local'),
        trailing: readOnly
            ? null
            : IconButton(
                icon: const Icon(Icons.close),
                onPressed: () =>
                    remove((t) => t.locationId == null && t.itemId == itemId),
              ),
      ),
    );

    // Agrupa locais e itens soltos pelo cliente de cada um (não o da
    // tarefa): um frame por cliente reúne tudo dele; sem cliente, cada
    // local/item solto continua no seu próprio frame (como já era).
    final locationsByClient = <String, List<String>>{};
    final locationsNoClient = <String>[];
    for (final locId in locationsToShow) {
      final cid = locById[locId]?.clientId;
      if (cid != null) {
        locationsByClient.putIfAbsent(cid, () => []).add(locId);
      } else {
        locationsNoClient.add(locId);
      }
    }
    final looseItemsByClient = <String, List<String>>{};
    final looseItemsNoClient = <String>[];
    for (final itemId in looseItems) {
      final cid = itemById[itemId]?.clientId;
      if (cid != null) {
        looseItemsByClient.putIfAbsent(cid, () => []).add(itemId);
      } else {
        looseItemsNoClient.add(itemId);
      }
    }
    final clientIds =
        ({...locationsByClient.keys, ...looseItemsByClient.keys}).toList()
          ..sort(
            (a, b) => (clientNameById[a] ?? '').toLowerCase().compareTo(
              (clientNameById[b] ?? '').toLowerCase(),
            ),
          );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (targets.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                readOnly
                    ? 'Nenhum local ou item.'
                    : 'Opcional. Adicione clientes, locais e itens.',
                style: theme.textTheme.bodySmall,
              ),
            ),
          for (final cid in clientIds)
            _ClientGroup(
              name: clientNameById[cid] ?? 'Cliente',
              readOnly: readOnly,
              onRemoveAll: () => remove(
                (t) =>
                    (t.locationId != null &&
                        (locationsByClient[cid] ?? const []).contains(
                          t.locationId,
                        )) ||
                    (t.locationId == null &&
                        t.itemId != null &&
                        (looseItemsByClient[cid] ?? const []).contains(
                          t.itemId,
                        )),
              ),
              children: [
                for (final locId in locationsByClient[cid] ?? const [])
                  locationGroup(locId),
                for (final itemId in looseItemsByClient[cid] ?? const [])
                  looseItemTile(itemId),
              ],
            ),
          for (final locId in locationsNoClient) locationGroup(locId),
          for (final itemId in looseItemsNoClient) looseItemTile(itemId),
          if (!readOnly) ...[
            const SizedBox(height: 4),
            OutlinedButton.icon(
              onPressed: () => _openPicker(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Adicionar cliente, local ou item'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openPicker(BuildContext context, WidgetRef ref) async {
    final result = await Navigator.of(context).push<List<TaskTargetInput>>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => TaskTargetPickerScreen(
          clientId: clientId,
          initialTargets: targets,
        ),
      ),
    );
    FocusManager.instance.primaryFocus?.unfocus();
    if (result == null) return;
    onChanged(result);
  }
}

/// Frame de um cliente nos alvos: cabeçalho + locais/itens dele (agrupados
/// pelo cliente de cada um, não o da tarefa — ver doc de [TaskTargetsField]).
class _ClientGroup extends StatelessWidget {
  const _ClientGroup({
    required this.name,
    required this.readOnly,
    required this.onRemoveAll,
    required this.children,
  });

  final String name;
  final bool readOnly;
  final VoidCallback onRemoveAll;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 4, 4, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.business_outlined, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    'Cliente: $name',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
              ),
              if (!readOnly)
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Remover cliente e seus locais/itens',
                  onPressed: onRemoveAll,
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

/// Grupo de um local nos alvos: cabeçalho + itens vinculados (sempre visíveis)
/// + botão "Ver endereço e contato" que revela o sub-frame.
class _LocationGroup extends StatefulWidget {
  const _LocationGroup({
    required this.location,
    required this.readOnly,
    required this.itemNames,
    required this.onRemoveLocation,
    required this.onRemoveItem,
  });

  final LocalLocation? location;
  final bool readOnly;
  final List<({String id, String name})> itemNames;
  final VoidCallback onRemoveLocation;
  final ValueChanged<String> onRemoveItem;

  @override
  State<_LocationGroup> createState() => _LocationGroupState();
}

class _LocationGroupState extends State<_LocationGroup> {
  bool _showInfo = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = widget.location;
    final name = loc == null || loc.name.isEmpty ? 'Local' : loc.name;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 4, 4, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.place_outlined, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    'Local: $name',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
              ),
              if (!widget.readOnly)
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Remover local e seus itens',
                  onPressed: widget.onRemoveLocation,
                ),
            ],
          ),
          for (final it in widget.itemNames)
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Row(
                children: [
                  const Icon(Icons.inventory_2_outlined, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(it.name)),
                  if (!widget.readOnly)
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => widget.onRemoveItem(it.id),
                    ),
                ],
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _showInfo = !_showInfo),
              icon: Icon(
                _showInfo
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 18,
              ),
              label: Text(
                _showInfo
                    ? 'Ocultar endereço e contato'
                    : 'Ver endereço e contato',
              ),
            ),
          ),
          if (_showInfo && loc != null) _LocationInfo(location: loc),
        ],
      ),
    );
  }
}

/// Endereço + contatos do cliente *do local* (não o da tarefa — um local
/// pode ser de outro cliente, ou de nenhum) em texto plano num sub-frame.
class _LocationInfo extends ConsumerWidget {
  const _LocationInfo({required this.location});

  final LocalLocation location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final addr = locationAddressLine(location);
    final locClientId = location.clientId;
    final contacts = locClientId == null
        ? const <Contact>[]
        : (ref
                  .watch(contactsProvider((ContactScope.client, locClientId)))
                  .value ??
              const <Contact>[]);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline),
        color: theme.colorScheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Endereço', style: theme.textTheme.labelSmall),
          Text(addr.isEmpty ? '—' : addr),
          const SizedBox(height: 6),
          Text('Contatos do cliente', style: theme.textTheme.labelSmall),
          if (locClientId == null)
            const Text('—')
          else if (contacts.isEmpty)
            const Text('—')
          else
            for (final c in contacts)
              Text(
                [
                  c.name,
                  if (c.role.isNotEmpty) '(${c.role})',
                  if (c.phone.isNotEmpty) c.phone,
                  if (c.email.isNotEmpty) c.email,
                ].join(' · '),
              ),
        ],
      ),
    );
  }
}
