import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/widgets/form_sheet.dart';
import '../../clients/presentation/client_picker.dart' show accentFold;
import '../../contacts/data/contact_repository.dart';
import '../../items/application/items_provider.dart';
import '../../locations/application/locations_provider.dart';
import '../../locations/data/location_mapper.dart';
import '../../locations/presentation/location_picker.dart';
import '../data/task_mapper.dart';

/// Frame "Alvos" da tarefa: locais e itens do cliente. Um item vinculado a um
/// local aparece aninhado sob ele (sempre visível); endereço + contatos do
/// cliente ficam atrás de um botão "Ver endereço e contato".
class TaskTargetsField extends ConsumerWidget {
  const TaskTargetsField({
    super.key,
    required this.clientId,
    required this.targets,
    required this.onChanged,
    this.readOnly = false,
  });

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

    // Agrupa: locationId -> itens; e itens soltos (sem local).
    final byLocation = <String, List<String>>{}; // locId -> [itemId?]
    final looseItems = <String>[];
    final looseLocations = <String>{};
    for (final t in targets) {
      if (t.locationId != null) {
        byLocation.putIfAbsent(t.locationId!, () => []);
        if (t.itemId != null) byLocation[t.locationId!]!.add(t.itemId!);
        looseLocations.add(t.locationId!);
      } else if (t.itemId != null) {
        looseItems.add(t.itemId!);
      }
    }
    // um local só entra em looseLocations se tiver uma linha "só local"
    final standaloneLocations = targets
        .where((t) => t.locationId != null && t.itemId == null)
        .map((t) => t.locationId!)
        .toSet();

    void remove(bool Function(TaskTargetInput) test) {
      onChanged([
        for (final t in targets)
          if (!test(t)) t,
      ]);
    }

    final locationsToShow = {...standaloneLocations, ...byLocation.keys};

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
                    : 'Opcional. Adicione locais e itens do cliente.',
                style: theme.textTheme.bodySmall,
              ),
            ),
          for (final locId in locationsToShow)
            _LocationGroup(
              location: locById[locId],
              clientId: clientId,
              readOnly: readOnly,
              itemNames: [
                for (final itemId in byLocation[locId] ?? const [])
                  (id: itemId, name: itemById[itemId]?.name ?? 'Item'),
              ],
              onRemoveLocation: () => remove((t) => t.locationId == locId),
              onRemoveItem: (itemId) => remove(
                (t) => t.locationId == locId && t.itemId == itemId,
              ),
            ),
          for (final itemId in looseItems)
            Container(
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
                        onPressed: () => remove(
                          (t) => t.locationId == null && t.itemId == itemId,
                        ),
                      ),
              ),
            ),
          if (!readOnly && clientId != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _addLocation(context, ref),
                    icon: const Icon(Icons.add_location_alt_outlined),
                    label: const Text('Adicionar local'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _addItem(context, ref, itemById, locById),
                    icon: const Icon(Icons.add),
                    label: const Text('Adicionar item'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _addLocation(BuildContext context, WidgetRef ref) async {
    final id = await pickLocation(context, clientId: clientId!);
    FocusManager.instance.primaryFocus?.unfocus();
    if (id == null || id.isEmpty) return;
    if (targets.any((t) => t.locationId == id && t.itemId == null)) return;
    onChanged([...targets, TaskTargetInput(locationId: id)]);
  }

  Future<void> _addItem(
    BuildContext context,
    WidgetRef ref,
    Map<String, LocalItem> itemById,
    Map<String, LocalLocation> locById,
  ) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ItemPickerSheet(clientId: clientId!),
    );
    FocusManager.instance.primaryFocus?.unfocus();
    if (picked == null) return;
    final it = itemById[picked];
    final next = [...targets];
    final locId = it?.locationId;
    if (locId != null) {
      // encaixa o item sob o local; remove a linha "só local" redundante
      next.removeWhere((t) => t.locationId == locId && t.itemId == null);
      if (!next.any((t) => t.locationId == locId && t.itemId == picked)) {
        next.add(TaskTargetInput(locationId: locId, itemId: picked));
      }
    } else if (!next.any((t) => t.locationId == null && t.itemId == picked)) {
      next.add(TaskTargetInput(itemId: picked));
    }
    onChanged(next);
  }
}

/// Grupo de um local nos alvos: cabeçalho + itens vinculados (sempre visíveis)
/// + botão "Ver endereço e contato" que revela o sub-frame.
class _LocationGroup extends StatefulWidget {
  const _LocationGroup({
    required this.location,
    required this.clientId,
    required this.readOnly,
    required this.itemNames,
    required this.onRemoveLocation,
    required this.onRemoveItem,
  });

  final LocalLocation? location;
  final String? clientId;
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
                _showInfo ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 18,
              ),
              label: Text(
                _showInfo ? 'Ocultar endereço e contato' : 'Ver endereço e contato',
              ),
            ),
          ),
          if (_showInfo && loc != null)
            _LocationInfo(clientId: widget.clientId, location: loc),
        ],
      ),
    );
  }
}

/// Endereço + contatos do cliente em texto plano dentro de um sub-frame.
class _LocationInfo extends ConsumerWidget {
  const _LocationInfo({required this.clientId, required this.location});

  final String? clientId;
  final LocalLocation location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final addr = locationAddressLine(location);
    final contacts = clientId == null
        ? const <Contact>[]
        : (ref
                  .watch(contactsProvider((ContactScope.client, clientId!)))
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
          if (contacts.isEmpty)
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

class _ItemPickerSheet extends ConsumerStatefulWidget {
  const _ItemPickerSheet({required this.clientId});
  final String clientId;

  @override
  ConsumerState<_ItemPickerSheet> createState() => _ItemPickerSheetState();
}

class _ItemPickerSheetState extends ConsumerState<_ItemPickerSheet> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final items =
        ref
            .watch(itemsByClientProvider(widget.clientId))
            .where(
              (i) =>
                  _q.isEmpty || accentFold(i.name).contains(accentFold(_q)),
            )
            .toList()
          ..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );
    return FormSheet(
      title: 'Item do cliente',
      children: [
        TextField(
          decoration: const InputDecoration(
            hintText: 'Pesquise um item',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (v) => setState(() => _q = v),
        ),
        const SizedBox(height: 8),
        ...items.map(
          (i) => ListTile(
            dense: true,
            title: Text(i.name),
            onTap: () => Navigator.of(context).pop(i.id),
          ),
        ),
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('Nenhum item para este cliente.'),
          ),
      ],
    );
  }
}
