import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/widgets/brand_app_bar.dart';
import '../../../core/widgets/form_sheet.dart';
import '../application/items_provider.dart';
import 'field_options_editor.dart';

const _dataTypeLabels = {
  'text': 'Texto',
  'number': 'Número',
  'date': 'Somente data',
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
    // Opções (ativas e inativas) como linhas editáveis; renomear/inativar
    // mantém o id, então os itens que já usam a opção não são afetados.
    //
    // `await ...watchOptions(id).first`, não `ref.read(itemFieldOptionsProvider
    // (id)).value` — este provider só é observado aqui (nada mais nesta tela o
    // mantém "quente"), então na primeira leitura o stream ainda não emitiu e
    // `.value` vem `null` mesmo com as opções já salvas no banco. Reproduzido
    // no emulador: editar um campo lista logo após criá-lo mostrava a lista
    // de opções vazia — salvar nesse estado inativaria Azul/Verde (ausentes
    // do envio = inativadas), um efeito colateral que o admin não pediu.
    final initialOptions = existing?.dataType == 'select'
        ? await ref
              .read(itemFieldDefRepositoryProvider)
              .watchOptions(existing!.id)
              .first
        : const <LocalItemFieldOption>[];
    if (!mounted) return; // o await acima pode ultrapassar a vida da tela

    final result = await showModalBottomSheet<_FieldFormResult>(
      context: context,
      isScrollControlled: true,
      builder: (c) => _FieldFormSheet(
        existing: existing,
        types: types,
        initialOptions: initialOptions,
      ),
    );
    if (result == null) return;

    try {
      final repo = ref.read(itemFieldDefRepositoryProvider);
      if (existing == null) {
        await repo.create(
          itemTypeId: result.itemTypeId,
          label: result.label,
          dataType: result.dataType,
          required: result.required,
          options: result.options,
        );
      } else {
        await repo.update(
          id: existing.id,
          baseVersion: existing.version,
          itemTypeId: result.itemTypeId,
          label: result.label,
          dataType: result.dataType,
          required: result.required,
          options: result.options,
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

typedef _FieldFormResult = ({
  String label,
  String dataType,
  String? itemTypeId,
  bool required,
  List<FieldOptionInput> options,
});

/// Conteúdo da folha de criar/editar campo. `StatefulWidget` próprio (em vez
/// de `StatefulBuilder`) para que os `TextEditingController` sejam
/// descartados no momento certo pelo framework — `State.dispose()` só roda
/// depois que a folha de fato saiu da árvore (após a animação de fechar).
/// Descartá-los "na mão" assim que `Navigator.pop` retorna quebra o app: o
/// `TextField` ainda está montado terminando a transição de saída e tenta
/// reagir a um controller já morto (`ChangeNotifier` usado após `dispose()`,
/// assert `_dependents.isEmpty` — reproduzido ao testar no emulador). Por
/// isso o resultado (rótulo, tipo, opções...) sai pelo valor do `pop`, não
/// lido depois de fora.
class _FieldFormSheet extends StatefulWidget {
  const _FieldFormSheet({
    required this.existing,
    required this.types,
    required this.initialOptions,
  });

  final LocalItemFieldDef? existing;
  final List<LocalItemType> types;
  final List<LocalItemFieldOption> initialOptions;

  @override
  State<_FieldFormSheet> createState() => _FieldFormSheetState();
}

class _FieldFormSheetState extends State<_FieldFormSheet> {
  late final _labelCtrl = TextEditingController(
    text: widget.existing?.label ?? '',
  );
  late final List<FieldOptionDraft> _drafts = [
    for (final o in widget.initialOptions) FieldOptionDraft.from(o),
  ];
  String? _optionsError;
  late String _dataType = widget.existing?.dataType ?? 'text';
  late bool _required = widget.existing?.required ?? false;
  late String? _typeId = widget.existing?.itemTypeId;

  @override
  void dispose() {
    _labelCtrl.dispose();
    for (final d in _drafts) {
      d.controller.dispose();
    }
    super.dispose();
  }

  void _save() {
    var options = const <FieldOptionInput>[];
    if (_dataType == 'select') {
      final r = collectFieldOptions(_drafts);
      if (r.error != null) {
        setState(() => _optionsError = r.error);
        return;
      }
      options = r.options!;
    }
    Navigator.pop(context, (
      label: _labelCtrl.text.trim(),
      dataType: _dataType,
      itemTypeId: _typeId,
      required: _required,
      options: options,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return FormSheet(
      title: widget.existing == null ? 'Novo campo' : 'Editar campo',
      children: [
        TextField(
          controller: _labelCtrl,
          decoration: const InputDecoration(labelText: 'Descrição'),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _dataType,
          decoration: const InputDecoration(labelText: 'Tipo do dado'),
          items: [
            for (final e in _dataTypeLabels.entries)
              DropdownMenuItem(value: e.key, child: Text(e.value)),
          ],
          onChanged: (v) => setState(() {
            _dataType = v ?? 'text';
            if (_dataType == 'select' && _drafts.isEmpty) {
              _drafts.add(FieldOptionDraft());
            }
          }),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String?>(
          initialValue: _typeId,
          decoration: const InputDecoration(labelText: 'Aplica-se a'),
          items: [
            const DropdownMenuItem(
              value: null,
              child: Text('Todos os itens (global)'),
            ),
            for (final t in widget.types)
              DropdownMenuItem(value: t.id, child: Text(t.name)),
          ],
          onChanged: (v) => setState(() => _typeId = v),
        ),
        if (_dataType == 'select') ...[
          const SizedBox(height: 12),
          FieldOptionsEditor(drafts: _drafts, errorText: _optionsError),
        ],
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Obrigatório'),
          value: _required,
          onChanged: (v) => setState(() => _required = v),
        ),
        const SizedBox(height: 16),
        FilledButton(onPressed: _save, child: const Text('Salvar')),
      ],
    );
  }
}
