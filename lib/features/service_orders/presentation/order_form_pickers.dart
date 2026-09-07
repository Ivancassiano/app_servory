import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/widgets/form_sheet.dart';
import '../../clients/application/clients_provider.dart';
import '../../items/application/items_provider.dart';

/// Um alvo escolhido no seletor: um item do cadastro. Cada alvo vira uma
/// linha da ordem.
typedef OrderTarget = ({String itemId});

/// minúsculas + sem acento (mesma lógica de SearchableListView).
String accentFold(String s) {
  const from = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
  const to = 'aaaaaeeeeiiiiooooouuuucn';
  final b = StringBuffer();
  for (final ch in s.toLowerCase().split('')) {
    final i = from.indexOf(ch);
    b.write(i == -1 ? ch : to[i]);
  }
  return b.toString();
}

/// Bottom sheet de busca + seleção de cliente. Retorna o id escolhido.
Future<String?> pickClient(BuildContext context) =>
    showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _ClientPickerSheet(),
    );

class _ClientPickerSheet extends ConsumerStatefulWidget {
  const _ClientPickerSheet();

  @override
  ConsumerState<_ClientPickerSheet> createState() => _ClientPickerSheetState();
}

class _ClientPickerSheetState extends ConsumerState<_ClientPickerSheet> {
  String _q = '';
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final clients =
        (ref.watch(clientListProvider).value ?? const <LocalClient>[])
            .where(
              (c) => _q.isEmpty || accentFold(c.name).contains(accentFold(_q)),
            )
            .toList()
          ..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );

    return _SheetScaffold(
      title: 'Cliente',
      onConfirm: _selected == null
          ? null
          : () => Navigator.of(context).pop(_selected),
      confirmLabel: 'Selecionar cliente',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Pesquise o cliente',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (v) => setState(() => _q = v),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: clients.length,
              itemBuilder: (_, i) {
                final c = clients[i];
                final sel = c.id == _selected;
                return ListTile(
                  dense: true,
                  selected: sel,
                  title: Text(c.name),
                  trailing: sel ? const Icon(Icons.check) : null,
                  onTap: () => setState(() => _selected = c.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet: a árvore de itens do cliente, com checkbox em qualquer nível,
/// busca e cadastro rápido (só nome). Retorna os itens marcados; `initial`
/// pré-marca o que já estava selecionado.
Future<List<OrderTarget>?> pickOrderTargets(
  BuildContext context, {
  required String clientId,
  required Set<OrderTarget> initial,
}) => showModalBottomSheet<List<OrderTarget>>(
  context: context,
  isScrollControlled: true,
  builder: (_) => _TargetsPickerSheet(clientId: clientId, initial: initial),
);

class _TargetsPickerSheet extends ConsumerStatefulWidget {
  const _TargetsPickerSheet({required this.clientId, required this.initial});
  final String clientId;
  final Set<OrderTarget> initial;

  @override
  ConsumerState<_TargetsPickerSheet> createState() =>
      _TargetsPickerSheetState();
}

class _TargetsPickerSheetState extends ConsumerState<_TargetsPickerSheet> {
  String _q = '';
  late final Set<String> _sel = {for (final t in widget.initial) t.itemId};

  bool _matches(String text) =>
      _q.isEmpty || accentFold(text).contains(accentFold(_q));

  Future<void> _newItem(String? parentId) async {
    final name = await _promptName(context, 'Novo item');
    if (name == null || name.isEmpty) return;
    final id = await ref
        .read(itemRepositoryProvider)
        .create(
          clientId: widget.clientId,
          parentItemId: parentId,
          fields: ItemFields(name: name),
        );
    if (mounted) setState(() => _sel.add(id));
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(itemsByClientProvider(widget.clientId)).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final childrenOf = <String?, List<LocalItem>>{};
    for (final i in items) {
      childrenOf.putIfAbsent(i.parentItemId, () => []).add(i);
    }
    final roots = childrenOf[null] ?? const <LocalItem>[];

    return _SheetScaffold(
      title: 'Itens da visita',
      confirmLabel: _sel.isEmpty ? 'Adicionar' : 'Adicionar (${_sel.length})',
      onConfirm: () =>
          Navigator.of(context).pop([for (final id in _sel) (itemId: id)]),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            decoration: const InputDecoration(
              hintText: 'Pesquise um item',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (v) => setState(() => _q = v),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final r in roots)
                  _ItemNode(
                    item: r,
                    childrenOf: childrenOf,
                    depth: 0,
                    query: _q,
                    matches: _matches,
                    checked: _sel.contains,
                    onToggle: (id, v) =>
                        setState(() => v ? _sel.add(id) : _sel.remove(id)),
                    onNewChild: (id) => _newItem(id),
                  ),
                TextButton.icon(
                  onPressed: () => _newItem(null),
                  icon: const Icon(Icons.add),
                  label: const Text('Novo item'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemNode extends StatelessWidget {
  const _ItemNode({
    required this.item,
    required this.childrenOf,
    required this.depth,
    required this.query,
    required this.matches,
    required this.checked,
    required this.onToggle,
    required this.onNewChild,
  });

  final LocalItem item;
  final Map<String?, List<LocalItem>> childrenOf;
  final int depth;
  final String query;
  final bool Function(String) matches;
  final bool Function(String) checked;
  final void Function(String id, bool v) onToggle;
  final void Function(String parentId) onNewChild;

  @override
  Widget build(BuildContext context) {
    final kids = childrenOf[item.id] ?? const <LocalItem>[];
    final selfHit = matches(item.name);
    final visibleKids = kids
        .where((k) => query.isEmpty || selfHit || _subtreeHits(k))
        .toList();
    if (!selfHit && visibleKids.isEmpty && query.isNotEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CheckboxListTile(
          dense: true,
          contentPadding: EdgeInsets.only(left: 16.0 * depth),
          controlAffinity: ListTileControlAffinity.leading,
          value: checked(item.id),
          onChanged: (v) => onToggle(item.id, v ?? false),
          title: Text(
            item.name,
            style: depth == 0
                ? const TextStyle(fontWeight: FontWeight.w600)
                : null,
          ),
        ),
        for (final k in visibleKids)
          _ItemNode(
            item: k,
            childrenOf: childrenOf,
            depth: depth + 1,
            query: query,
            matches: matches,
            checked: checked,
            onToggle: onToggle,
            onNewChild: onNewChild,
          ),
        Padding(
          padding: EdgeInsets.only(left: 16.0 * (depth + 1)),
          child: Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => onNewChild(item.id),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Novo subitem'),
            ),
          ),
        ),
      ],
    );
  }

  bool _subtreeHits(LocalItem node) {
    if (matches(node.name)) return true;
    for (final k in childrenOf[node.id] ?? const <LocalItem>[]) {
      if (_subtreeHits(k)) return true;
    }
    return false;
  }
}

Future<String?> _promptName(BuildContext context, String title) {
  final c = TextEditingController();
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => FormSheet(
      title: title,
      children: [
        TextField(
          controller: c,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nome'),
          onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(c.text.trim()),
          child: const Text('Adicionar'),
        ),
      ],
    ),
  );
}

/// Campo "Cliente" do form de criação: mostra o nome escolhido + botão.
class ClientPickerField extends StatelessWidget {
  const ClientPickerField({
    super.key,
    required this.clientName,
    required this.onPick,
  });

  final String? clientName;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final chosen = clientName != null && clientName!.isNotEmpty;
    return InputDecorator(
      decoration: const InputDecoration(labelText: 'Cliente'),
      child: Row(
        children: [
          Expanded(
            child: Text(
              chosen ? clientName! : 'Nenhum cliente',
              style: chosen
                  ? null
                  : TextStyle(color: Theme.of(context).hintColor),
            ),
          ),
          TextButton(
            onPressed: onPick,
            child: Text(chosen ? 'Trocar' : 'Selecionar cliente'),
          ),
        ],
      ),
    );
  }
}

/// Campo "Itens" do form de criação: lista os alvos escolhidos + botão.
class TargetsField extends StatelessWidget {
  const TargetsField({
    super.key,
    required this.clientId,
    required this.targets,
    required this.itemName,
    required this.onAdd,
    required this.onRemove,
  });

  final String? clientId;
  final List<OrderTarget> targets;
  final String Function(String id) itemName;
  final VoidCallback onAdd;
  final void Function(OrderTarget) onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            targets.isEmpty ? 'Itens' : 'Itens (${targets.length})',
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
        if (targets.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Text('Opcional. Adicione os itens da visita.'),
          )
        else
          for (final t in targets)
            ListTile(
              dense: true,
              contentPadding: const EdgeInsets.only(left: 12),
              title: Text(
                itemName(t.itemId).isEmpty ? 'Item' : itemName(t.itemId),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => onRemove(t),
              ),
            ),
        const SizedBox(height: 4),
        OutlinedButton.icon(
          onPressed: clientId == null ? null : onAdd,
          icon: const Icon(Icons.add),
          label: const Text('Adicionar'),
        ),
      ],
    );
  }
}

class _SheetScaffold extends StatelessWidget {
  const _SheetScaffold({
    required this.title,
    required this.child,
    required this.confirmLabel,
    required this.onConfirm,
  });

  final String title;
  final Widget child;
  final String confirmLabel;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Flexible(child: child),
              const SizedBox(height: 12),
              FilledButton(onPressed: onConfirm, child: Text(confirmLabel)),
            ],
          ),
        ),
      ),
    );
  }
}
