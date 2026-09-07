import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../clients/application/clients_provider.dart';
import '../../equipments/application/equipments_provider.dart';
import '../../locations/application/locations_provider.dart';

/// Um alvo escolhido no seletor: um local (equipmentId nulo) ou um equipamento
/// (o local vem junto por conveniência de exibição).
typedef OrderTarget = ({String locationId, String? equipmentId});

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
Future<String?> pickClient(BuildContext context) => showModalBottomSheet<String>(
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
    final clients = (ref.watch(clientListProvider).value ?? const <LocalClient>[])
        .where((c) => _q.isEmpty || accentFold(c.name).contains(accentFold(_q)))
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

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

/// Bottom sheet: árvore local › equipamentos do cliente, com checkbox em
/// qualquer nível, busca e cadastro rápido (só nome). Retorna os alvos
/// marcados; não sobrepõe o que já estava selecionado (`initial`).
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
  late final Set<String> _locSel; // locais marcados (item sem equipamento)
  late final Set<String> _eqSel; // equipamentos marcados

  @override
  void initState() {
    super.initState();
    _locSel = {
      for (final t in widget.initial)
        if (t.equipmentId == null) t.locationId,
    };
    _eqSel = {
      for (final t in widget.initial)
        if (t.equipmentId != null) t.equipmentId!,
    };
  }

  bool _matches(String text) =>
      _q.isEmpty || accentFold(text).contains(accentFold(_q));

  Future<void> _newLocation() async {
    final name = await _promptName(context, 'Novo local');
    if (name == null || name.isEmpty) return;
    final id = await ref
        .read(locationRepositoryProvider)
        .create(
          clientId: widget.clientId,
          name: name,
          contactPerson: '',
          phone: '',
          notes: '',
        );
    if (mounted) setState(() => _locSel.add(id));
  }

  Future<void> _newEquipment(String locationId) async {
    final name = await _promptName(context, 'Novo equipamento');
    if (name == null || name.isEmpty) return;
    final id = await ref
        .read(equipmentRepositoryProvider)
        .create(
          locationId: locationId,
          name: name,
          brand: '',
          model: '',
          notes: '',
        );
    if (mounted) setState(() => _eqSel.add(id));
  }

  @override
  Widget build(BuildContext context) {
    final locations =
        (ref.watch(locationListProvider).value ?? const <LocalLocation>[])
            .where((l) => l.clientId == widget.clientId)
            .toList()
          ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final equipsByLoc = <String, List<LocalEquipment>>{};
    for (final e
        in ref.watch(equipmentListProvider).value ?? const <LocalEquipment>[]) {
      equipsByLoc.putIfAbsent(e.locationId, () => []).add(e);
    }

    final total = _locSel.length + _eqSel.length;

    return _SheetScaffold(
      title: 'Locais e equipamentos',
      confirmLabel: total == 0 ? 'Adicionar' : 'Adicionar ($total)',
      onConfirm: () {
        final out = <OrderTarget>[
          for (final l in _locSel) (locationId: l, equipmentId: null),
          for (final e in _eqSel)
            (
              locationId: equipsByLoc.entries
                  .firstWhere(
                    (kv) => kv.value.any((x) => x.id == e),
                    orElse: () => const MapEntry('', []),
                  )
                  .key,
              equipmentId: e,
            ),
        ];
        Navigator.of(context).pop(out);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            decoration: const InputDecoration(
              hintText: 'Pesquise local ou equipamento',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (v) => setState(() => _q = v),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final loc in locations)
                  _LocationNode(
                    loc: loc,
                    equips: equipsByLoc[loc.id] ?? const [],
                    query: _q,
                    matches: _matches,
                    locChecked: _locSel.contains(loc.id),
                    eqChecked: _eqSel.contains,
                    onLocToggle: (v) => setState(
                      () => v ? _locSel.add(loc.id) : _locSel.remove(loc.id),
                    ),
                    onEqToggle: (id, v) => setState(
                      () => v ? _eqSel.add(id) : _eqSel.remove(id),
                    ),
                    onNewEquipment: () => _newEquipment(loc.id),
                  ),
                TextButton.icon(
                  onPressed: _newLocation,
                  icon: const Icon(Icons.add),
                  label: const Text('Novo local'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationNode extends StatelessWidget {
  const _LocationNode({
    required this.loc,
    required this.equips,
    required this.query,
    required this.matches,
    required this.locChecked,
    required this.eqChecked,
    required this.onLocToggle,
    required this.onEqToggle,
    required this.onNewEquipment,
  });

  final LocalLocation loc;
  final List<LocalEquipment> equips;
  final String query;
  final bool Function(String) matches;
  final bool locChecked;
  final bool Function(String) eqChecked;
  final ValueChanged<bool> onLocToggle;
  final void Function(String id, bool v) onEqToggle;
  final VoidCallback onNewEquipment;

  @override
  Widget build(BuildContext context) {
    final locHit = matches(loc.name);
    final visibleEquips = equips
        .where((e) => query.isEmpty || locHit || matches(e.name))
        .toList();
    if (!locHit && visibleEquips.isEmpty && query.isNotEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CheckboxListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: locChecked,
          onChanged: (v) => onLocToggle(v ?? false),
          title: Text(
            loc.name.toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Column(
            children: [
              for (final e in visibleEquips)
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: eqChecked(e.id),
                  onChanged: (v) => onEqToggle(e.id, v ?? false),
                  title: Text(e.name),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: onNewEquipment,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Novo equipamento'),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 8),
      ],
    );
  }
}

Future<String?> _promptName(BuildContext context, String title) {
  final c = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: c,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Nome'),
        onSubmitted: (v) => Navigator.of(context).pop(v.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(c.text.trim()),
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

/// Campo "Locais" do form de criação: lista os alvos escolhidos + botão.
class TargetsField extends StatelessWidget {
  const TargetsField({
    super.key,
    required this.clientId,
    required this.targets,
    required this.locationName,
    required this.equipmentName,
    required this.onAdd,
    required this.onRemove,
  });

  final String? clientId;
  final List<OrderTarget> targets;
  final String Function(String id) locationName;
  final String Function(String id) equipmentName;
  final VoidCallback onAdd;
  final void Function(OrderTarget) onRemove;

  @override
  Widget build(BuildContext context) {
    final byLoc = <String, List<OrderTarget>>{};
    for (final t in targets) {
      byLoc.putIfAbsent(t.locationId, () => []).add(t);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            targets.isEmpty ? 'Locais' : 'Locais (${targets.length})',
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
        if (targets.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Text('Opcional. Adicione locais/equipamentos da visita.'),
          )
        else
          for (final entry in byLoc.entries) ...[
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 2),
              child: Text(
                locationName(entry.key).isEmpty
                    ? 'Local'
                    : locationName(entry.key),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            for (final t in entry.value)
              ListTile(
                dense: true,
                contentPadding: const EdgeInsets.only(left: 12),
                title: Text(
                  t.equipmentId == null
                      ? 'Local (sem equipamento)'
                      : (equipmentName(t.equipmentId!).isEmpty
                            ? 'Equipamento'
                            : equipmentName(t.equipmentId!)),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => onRemove(t),
                ),
              ),
          ],
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
              FilledButton(
                onPressed: onConfirm,
                child: Text(confirmLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
