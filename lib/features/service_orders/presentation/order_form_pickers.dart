import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/form_sheet.dart';
import '../../clients/presentation/client_picker.dart';
import '../../items/application/items_provider.dart';

export '../../clients/presentation/client_picker.dart'
    show pickClient, ClientPickerField, accentFold;

/// Um alvo escolhido no seletor: um item do cadastro. Cada alvo vira uma
/// linha da ordem.
typedef OrderTarget = ({String itemId});

/// Bottom sheet: lista plana dos itens do cliente, com checkbox, busca e
/// cadastro rápido (só nome). Retorna os itens marcados; `initial` pré-marca
/// o que já estava selecionado.
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

  Future<void> _newItem() async {
    final name = await _promptName(context, 'Novo item');
    if (name == null || name.isEmpty) return;
    final id = await ref
        .read(itemRepositoryProvider)
        .create(
          clientId: widget.clientId,
          fields: ItemFields(name: name),
        );
    if (mounted) setState(() => _sel.add(id));
  }

  @override
  Widget build(BuildContext context) {
    final items =
        ref
            .watch(itemsByClientProvider(widget.clientId))
            .where(
              (i) =>
                  _q.isEmpty ||
                  accentFold(i.name).contains(accentFold(_q)),
            )
            .toList()
          ..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );

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
                for (final i in items)
                  CheckboxListTile(
                    dense: true,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: _sel.contains(i.id),
                    onChanged: (v) => setState(
                      () => (v ?? false) ? _sel.add(i.id) : _sel.remove(i.id),
                    ),
                    title: Text(i.name),
                  ),
                TextButton.icon(
                  onPressed: _newItem,
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
