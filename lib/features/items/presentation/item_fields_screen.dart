import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/widgets/brand_app_bar.dart';
import '../../../core/widgets/form_sheet.dart';
import '../application/items_provider.dart';

const _dataTypeLabels = {
  'text': 'Texto',
  'number': 'Número',
  'datetime': 'Data/hora',
  'boolean': 'Sim/Não',
  'select': 'Lista de opções',
};

/// Cadastro de metadados de item (admin/escritório) — define os campos que
/// aparecem no formulário do item, globais ou por tipo.
class ItemFieldsScreen extends ConsumerStatefulWidget {
  const ItemFieldsScreen({super.key});

  @override
  ConsumerState<ItemFieldsScreen> createState() => _ItemFieldsScreenState();
}

class _ItemFieldsScreenState extends ConsumerState<ItemFieldsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () =>
          ref.read(itemFieldDefRepositoryProvider).refresh().catchError((_) {}),
    );
  }

  @override
  Widget build(BuildContext context) {
    final defs = ref.watch(itemFieldDefListProvider).value ?? const [];
    final types = {
      for (final t in ref.watch(itemTypeListProvider).value ?? const [])
        t.id: t.name,
    };
    final global = defs.where((d) => d.itemTypeId == null).toList();
    final byType = <String, List<LocalItemFieldDef>>{};
    for (final d in defs.where((d) => d.itemTypeId != null)) {
      byType.putIfAbsent(d.itemTypeId!, () => []).add(d);
    }

    return Scaffold(
      appBar: brandAppBar(title: 'Campos de item'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(null),
        icon: const Icon(Icons.add),
        label: const Text('Novo campo'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          _group('Campos globais', global),
          for (final e in byType.entries)
            _group(types[e.key] ?? 'Tipo', e.value),
        ],
      ),
    );
  }

  Widget _group(String title, List<LocalItemFieldDef> defs) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 4),
        child: Text(title, style: Theme.of(context).textTheme.titleSmall),
      ),
      if (defs.isEmpty)
        const Padding(padding: EdgeInsets.all(8), child: Text('Nenhum campo.')),
      for (final d in defs)
        ListTile(
          title: Text(d.required ? '${d.label} *' : d.label),
          subtitle: Text(_dataTypeLabels[d.dataType] ?? d.dataType),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _delete(d),
          ),
          onTap: () => _edit(d),
        ),
    ],
  );

  Future<void> _delete(LocalItemFieldDef d) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Remover "${d.label}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(itemFieldDefRepositoryProvider).delete(d.id);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível remover.')),
        );
      }
    }
  }

  Future<void> _edit(LocalItemFieldDef? existing) async {
    final types = ref.read(itemTypeListProvider).value ?? const [];
    final labelCtrl = TextEditingController(text: existing?.label ?? '');
    final optionsCtrl = TextEditingController();
    if (existing?.dataType == 'select') {
      final opts =
          ref.read(itemFieldOptionsProvider(existing!.id)).value ?? const [];
      optionsCtrl.text = opts.map((o) => o.label).join('\n');
    }
    var dataType = existing?.dataType ?? 'text';
    var required = existing?.required ?? false;
    String? typeId = existing?.itemTypeId;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (c) => StatefulBuilder(
        builder: (c, setSt) => FormSheet(
          title: existing == null ? 'Novo campo' : 'Editar campo',
          children: [
            TextField(
              controller: labelCtrl,
              decoration: const InputDecoration(labelText: 'Descrição'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: dataType,
              decoration: const InputDecoration(labelText: 'Tipo do dado'),
              items: [
                for (final e in _dataTypeLabels.entries)
                  DropdownMenuItem(value: e.key, child: Text(e.value)),
              ],
              onChanged: (v) => setSt(() => dataType = v ?? 'text'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: typeId,
              decoration: const InputDecoration(labelText: 'Aplica-se a'),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Todos os itens (global)'),
                ),
                for (final t in types)
                  DropdownMenuItem(value: t.id, child: Text(t.name)),
              ],
              onChanged: (v) => setSt(() => typeId = v),
            ),
            if (dataType == 'select') ...[
              const SizedBox(height: 12),
              TextField(
                controller: optionsCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Opções (uma por linha)',
                ),
              ),
            ],
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Obrigatório'),
              value: required,
              onChanged: (v) => setSt(() => required = v),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
    if (saved != true) return;

    final options = dataType == 'select'
        ? [
            for (final l in optionsCtrl.text.split('\n'))
              if (l.trim().isNotEmpty) (label: l.trim(), value: l.trim()),
          ]
        : const <({String label, String value})>[];

    try {
      final repo = ref.read(itemFieldDefRepositoryProvider);
      if (existing == null) {
        await repo.create(
          itemTypeId: typeId,
          label: labelCtrl.text.trim(),
          dataType: dataType,
          required: required,
          options: options,
        );
      } else {
        await repo.update(
          id: existing.id,
          baseVersion: existing.version,
          itemTypeId: typeId,
          label: labelCtrl.text.trim(),
          dataType: dataType,
          required: required,
          options: options,
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível salvar o campo.')),
        );
      }
    }
  }
}
