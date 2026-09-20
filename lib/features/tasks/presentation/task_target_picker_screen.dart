import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../clients/application/clients_provider.dart';
import '../../clients/presentation/client_picker.dart' show accentFold;
import '../../items/application/items_provider.dart';
import '../../locations/application/locations_provider.dart';
import '../data/task_mapper.dart';

/// Tela cheia de seleção de alvos da tarefa: árvore Cliente > Local > Item
/// (mais locais/itens sem cliente e itens sem local, cada um na sua posição).
/// Marcar um local marca também os itens dele (pode desmarcar item a item);
/// marcar um cliente marca tudo dele (locais + itens). Marcar um item sozinho
/// não marca o local/cliente dele — eles só aparecem juntos no agrupamento
/// da tela de alvos, não como alvo à parte.
///
/// Com [clientId] (a tarefa já tem cliente), a busca fica restrita aos
/// locais/itens dele — regra do servidor: quando a tarefa TEM cliente, todo
/// alvo precisa ser dele (`resolveRefs`). Sem [clientId], a árvore cobre a
/// organização inteira, cliente por cliente.
///
/// Devolve a lista completa de alvos (substituindo [initialTargets]), ou
/// `null` se o usuário voltou sem confirmar.
class TaskTargetPickerScreen extends ConsumerStatefulWidget {
  const TaskTargetPickerScreen({
    super.key,
    required this.clientId,
    required this.initialTargets,
  });

  final String? clientId;
  final List<TaskTargetInput> initialTargets;

  @override
  ConsumerState<TaskTargetPickerScreen> createState() =>
      _TaskTargetPickerScreenState();
}

class _TaskTargetPickerScreenState
    extends ConsumerState<TaskTargetPickerScreen> {
  late final Set<String> _selectedLocationIds;
  late final Set<String> _selectedItemIds;
  String _q = '';

  @override
  void initState() {
    super.initState();
    _selectedLocationIds = {
      for (final t in widget.initialTargets)
        if (t.locationId != null && t.itemId == null) t.locationId!,
    };
    _selectedItemIds = {
      for (final t in widget.initialTargets)
        if (t.itemId != null) t.itemId!,
    };
  }

  @override
  Widget build(BuildContext context) {
    final clientId = widget.clientId;
    final locations = clientId == null
        ? ref.watch(locationListProvider).value ?? const []
        : ref.watch(locationsByClientProvider(clientId));
    final items = clientId == null
        ? ref.watch(itemListProvider).value ?? const []
        : ref.watch(itemsByClientProvider(clientId));
    final clients = clientId == null
        ? ref.watch(clientListProvider).value ?? const []
        : const <LocalClient>[];

    final itemLocationId = {for (final i in items) i.id: i.locationId};

    final tree = _buildTree(clients: clients, locations: locations, items: items);
    final visible = _filterTree(tree, _q);
    final selectedCount = _selectedLocationIds.length + _selectedItemIds.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          clientId == null
              ? 'Adicionar cliente, local ou item'
              : 'Adicionar local ou item',
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Pesquise cliente, local ou item',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _q = v),
            ),
          ),
          Expanded(
            child: visible.isEmpty
                ? const Center(child: Text('Nada encontrado.'))
                : ListView(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    children: [
                      for (final n in visible)
                        _NodeTile(node: n, depth: 0, screen: this),
                    ],
                  ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(12),
        child: FilledButton(
          onPressed: () =>
              Navigator.of(context).pop(_buildResult(itemLocationId)),
          child: Text(
            selectedCount == 0 ? 'Selecionar' : 'Selecionar ($selectedCount)',
          ),
        ),
      ),
    );
  }

  List<TaskTargetInput> _buildResult(Map<String, String?> itemLocationId) {
    final out = <TaskTargetInput>[];
    for (final locId in _selectedLocationIds) {
      out.add(TaskTargetInput(locationId: locId));
    }
    for (final itemId in _selectedItemIds) {
      out.add(
        TaskTargetInput(locationId: itemLocationId[itemId], itemId: itemId),
      );
    }
    return out;
  }

  /// `true`/`false`/indeterminado (`null`) — reflete a seleção do nó e, para
  /// cliente/local, dos filhos dele.
  bool? stateOf(_TreeNode node) {
    switch (node.kind) {
      case _NodeKind.item:
        return _selectedItemIds.contains(node.id);
      case _NodeKind.location:
        final bare = _selectedLocationIds.contains(node.id);
        if (node.children.isEmpty) return bare;
        final childStates = node.children.map(stateOf).toList();
        if (bare && childStates.every((s) => s == true)) return true;
        if (!bare && childStates.every((s) => s == false)) return false;
        return null;
      case _NodeKind.client:
        if (node.children.isEmpty) return false;
        final childStates = node.children.map(stateOf).toList();
        if (childStates.every((s) => s == true)) return true;
        if (childStates.every((s) => s == false)) return false;
        return null;
    }
  }

  void toggle(_TreeNode node) {
    final turnOn = stateOf(node) != true;
    setState(() => _applyCascade(node, turnOn));
  }

  void _applyCascade(_TreeNode node, bool on) {
    switch (node.kind) {
      case _NodeKind.item:
        if (on) {
          _selectedItemIds.add(node.id);
        } else {
          _selectedItemIds.remove(node.id);
        }
      case _NodeKind.location:
        if (on) {
          _selectedLocationIds.add(node.id);
        } else {
          _selectedLocationIds.remove(node.id);
        }
        for (final c in node.children) {
          _applyCascade(c, on);
        }
      case _NodeKind.client:
        for (final c in node.children) {
          _applyCascade(c, on);
        }
    }
  }
}

enum _NodeKind { client, location, item }

class _TreeNode {
  const _TreeNode({
    required this.kind,
    required this.id,
    required this.name,
    this.children = const [],
  });

  final _NodeKind kind;
  final String id;
  final String name;
  final List<_TreeNode> children;
}

int _byName(dynamic a, dynamic b) =>
    (a.name as String).toLowerCase().compareTo((b.name as String).toLowerCase());

List<_TreeNode> _buildTree({
  required List<LocalClient> clients,
  required List<LocalLocation> locations,
  required List<LocalItem> items,
}) {
  // `clients` só tem entrada quando a árvore é organização inteira (sem
  // clientId da tarefa — ver doc da classe); com clientId, vem vazia e todo
  // mundo (já filtrado pelo cliente por quem chamou) entra "solto", sem nó
  // de cliente por cima (redundante, já que só existe um).
  final knownClientIds = {for (final c in clients) c.id};

  final itemsByLocation = <String, List<LocalItem>>{};
  final itemsByClientNoLocation = <String, List<LocalItem>>{};
  final looseItems = <LocalItem>[];
  for (final i in items) {
    if (i.locationId != null) {
      itemsByLocation.putIfAbsent(i.locationId!, () => []).add(i);
    } else if (i.clientId != null && knownClientIds.contains(i.clientId)) {
      itemsByClientNoLocation.putIfAbsent(i.clientId!, () => []).add(i);
    } else {
      looseItems.add(i);
    }
  }

  final locationsByClient = <String, List<LocalLocation>>{};
  final looseLocations = <LocalLocation>[];
  for (final l in locations) {
    if (l.clientId != null && knownClientIds.contains(l.clientId)) {
      locationsByClient.putIfAbsent(l.clientId!, () => []).add(l);
    } else {
      looseLocations.add(l);
    }
  }

  _TreeNode itemNode(LocalItem i) => _TreeNode(
    kind: _NodeKind.item,
    id: i.id,
    name: i.name.isEmpty ? 'Item' : i.name,
  );

  _TreeNode locNode(LocalLocation l) {
    final its = [...itemsByLocation[l.id] ?? const []]..sort(_byName);
    return _TreeNode(
      kind: _NodeKind.location,
      id: l.id,
      name: l.name.isEmpty ? 'Local' : l.name,
      children: [for (final i in its) itemNode(i)],
    );
  }

  final sortedClients = [...clients]..sort(_byName);
  final result = <_TreeNode>[];
  for (final c in sortedClients) {
    final locs = [...locationsByClient[c.id] ?? const []]..sort(_byName);
    final directItems = [...itemsByClientNoLocation[c.id] ?? const []]
      ..sort(_byName);
    if (locs.isEmpty && directItems.isEmpty) continue;
    result.add(
      _TreeNode(
        kind: _NodeKind.client,
        id: c.id,
        name: c.name.isEmpty ? 'Cliente' : c.name,
        children: [
          for (final l in locs) locNode(l),
          for (final i in directItems) itemNode(i),
        ],
      ),
    );
  }
  final sortedLooseLocations = [...looseLocations]..sort(_byName);
  for (final l in sortedLooseLocations) {
    result.add(locNode(l));
  }
  final sortedLooseItems = [...looseItems]..sort(_byName);
  for (final i in sortedLooseItems) {
    result.add(itemNode(i));
  }
  return result;
}

List<_TreeNode> _filterTree(List<_TreeNode> nodes, String query) {
  if (query.trim().isEmpty) return nodes;
  final needle = accentFold(query);
  List<_TreeNode> rec(List<_TreeNode> ns) {
    final out = <_TreeNode>[];
    for (final n in ns) {
      final selfMatch = accentFold(n.name).contains(needle);
      if (selfMatch) {
        out.add(n);
        continue;
      }
      final filteredChildren = rec(n.children);
      if (filteredChildren.isNotEmpty) {
        out.add(
          _TreeNode(
            kind: n.kind,
            id: n.id,
            name: n.name,
            children: filteredChildren,
          ),
        );
      }
    }
    return out;
  }

  return rec(nodes);
}

class _NodeTile extends StatelessWidget {
  const _NodeTile({required this.node, required this.depth, required this.screen});

  final _TreeNode node;
  final int depth;
  final _TaskTargetPickerScreenState screen;

  @override
  Widget build(BuildContext context) {
    final state = screen.stateOf(node);
    final icon = switch (node.kind) {
      _NodeKind.client => Icons.business_outlined,
      _NodeKind.location => Icons.place_outlined,
      _NodeKind.item => Icons.inventory_2_outlined,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => screen.toggle(node),
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.0 * depth + 4, 2, 12, 2),
            child: Row(
              children: [
                Checkbox(
                  tristate: true,
                  value: state,
                  onChanged: (_) => screen.toggle(node),
                ),
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(node.name)),
              ],
            ),
          ),
        ),
        for (final c in node.children)
          _NodeTile(node: c, depth: depth + 1, screen: screen),
      ],
    );
  }
}
