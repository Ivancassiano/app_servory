import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/app_database.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/brand_app_bar.dart';
import '../../../core/widgets/detail_view.dart';
import '../../clients/application/clients_provider.dart';
import '../../clients/presentation/client_picker.dart';
import '../../contacts/data/contact_repository.dart';
import '../../contacts/presentation/contact_section.dart';
import '../../labels/data/qr_mapper.dart';
import '../../labels/presentation/qr_label_section.dart';
import '../../service_orders/presentation/related_service_orders_section.dart';
import '../application/item_edit_controller.dart';
import '../application/items_provider.dart';
import '../data/item_mapper.dart';
import 'item_custom_fields_form.dart';

/// Detalhe + criação + edição de um item. `itemId == 'new'` = criação.
class ItemDetailScreen extends ConsumerStatefulWidget {
  const ItemDetailScreen({
    super.key,
    required this.itemId,
    this.presetClientId,
    this.presetParentId,
  });

  final String itemId;
  final String? presetClientId;
  final String? presetParentId;

  bool get isNew => itemId == 'new';

  @override
  ConsumerState<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends ConsumerState<ItemDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _contactPerson = TextEditingController();
  final _phone = TextEditingController();
  final _street = TextEditingController();
  final _number = TextEditingController();
  final _district = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _postalCode = TextEditingController();
  final _brand = TextEditingController();
  final _model = TextEditingController();
  final _serial = TextEditingController();
  final _cost = TextEditingController();
  final _notes = TextEditingController();

  String? _clientId;
  String? _parentId;
  String? _typeId;
  Map<String, TypedFieldValue> _fieldValues = {};
  bool _seeded = false;
  bool _saving = false;
  bool _showContact = false;
  bool _showAddress = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _clientId = widget.presetClientId;
    _parentId = widget.presetParentId;
    // Puxa os catálogos de referência (tipos + campos personalizados) ao
    // abrir — melhor esforço. Sem isto o seletor de tipo pode mostrar um
    // tipo já apagado no servidor até a tela de catálogo ser reaberta.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(itemTypeRepositoryProvider).refresh().catchError((_) {});
      ref.read(itemFieldDefRepositoryProvider).refresh().catchError((_) {});
    });
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _contactPerson,
      _phone,
      _street,
      _number,
      _district,
      _city,
      _state,
      _postalCode,
      _brand,
      _model,
      _serial,
      _cost,
      _notes,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _seedFrom(LocalItem it) {
    if (_seeded) return;
    _seeded = true;
    _clientId = it.clientId;
    _parentId = it.parentItemId;
    _typeId = it.itemTypeId;
    _name.text = it.name;
    _contactPerson.text = it.contactPerson;
    _phone.text = it.phone;
    _street.text = it.street;
    _number.text = it.number;
    _district.text = it.district;
    _city.text = it.city;
    _state.text = it.state;
    _postalCode.text = it.postalCode;
    _brand.text = it.brand;
    _model.text = it.model;
    _serial.text = it.serialNumber ?? '';
    _cost.text = it.cost ?? '';
    _notes.text = it.notes;
    _showContact = it.contactPerson.isNotEmpty || it.phone.isNotEmpty;
    _showAddress = [
      it.postalCode,
      it.street,
      it.number,
      it.district,
      it.city,
      it.state,
    ].any((s) => s.isNotEmpty);
  }

  ItemFields _collect() => ItemFields(
    name: _name.text.trim(),
    itemTypeId: _typeId,
    contactPerson: _contactPerson.text.trim(),
    phone: _phone.text.trim(),
    brand: _brand.text.trim(),
    model: _model.text.trim(),
    serialNumber: _serial.text.trim(),
    cost: _cost.text.trim().isEmpty ? null : _cost.text.trim(),
    notes: _notes.text.trim(),
    address: ItemAddressInput(
      postalCode: _postalCode.text.trim(),
      street: _street.text.trim(),
      number: _number.text.trim(),
      district: _district.text.trim(),
      city: _city.text.trim(),
      state: _state.text.trim().toUpperCase(),
    ),
  );

  Future<void> _submit(LocalItem? existing) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_clientId == null) {
      setState(() => _error = 'Selecione o cliente.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final ctrl = ref.read(itemEditControllerProvider);
      final String id;
      if (existing == null) {
        id = await ctrl.create(
          clientId: _clientId!,
          parentItemId: _parentId,
          fields: _collect(),
        );
      } else {
        id = existing.id;
        await ctrl.update(
          itemId: id,
          baseVersion: existing.version,
          fields: _collect(),
        );
      }
      if (_fieldValues.isNotEmpty || existing != null) {
        await ref
            .read(itemFieldValueRepositoryProvider)
            .setValues(id, _fieldValues);
      }
      if (mounted) {
        if (existing == null) {
          context.pushReplacement('/items/$id');
        } else {
          context.pop();
        }
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Não foi possível salvar. Tente de novo.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isNew) return _form(context, null);
    final async = ref.watch(itemByIdProvider(widget.itemId));
    return async.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: brandAppBar(title: 'Item'),
        body: Center(child: Text('$e')),
      ),
      data: (it) {
        if (it == null) {
          return Scaffold(
            appBar: brandAppBar(title: 'Item'),
            body: const Center(child: Text('Item não encontrado.')),
          );
        }
        _seedFrom(it);
        return _viewMode ? _view(context, it) : _form(context, it);
      },
    );
  }

  bool _viewMode = true;

  Widget _view(BuildContext context, LocalItem it) {
    final types = {
      for (final t in ref.watch(itemTypeListProvider).value ?? const [])
        t.id: t.name,
    };
    final children = ref.watch(itemsByParentProvider(it.id));
    final addr = [
      it.street,
      it.number,
      it.district,
      it.city,
      it.state,
    ].where((s) => s.isNotEmpty).join(', ');

    return Scaffold(
      appBar: brandAppBar(
        title: it.name,
        subtitle: types[it.itemTypeId],
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => setState(() => _viewMode = false),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DetailRow(
            'Cliente',
            (ref.watch(clientListProvider).value ?? const [])
                .where((c) => c.id == it.clientId)
                .map((c) => c.name)
                .join(),
          ),
          if (types[it.itemTypeId] != null)
            DetailRow('Tipo', types[it.itemTypeId]!),
          if (addr.isNotEmpty) DetailRow('Endereço', addr),
          if (it.contactPerson.isNotEmpty)
            DetailRow('Contato', it.contactPerson),
          if (it.phone.isNotEmpty) DetailRow('Telefone', it.phone),
          if (it.brand.isNotEmpty || it.model.isNotEmpty)
            DetailRow('Marca/Modelo', '${it.brand} ${it.model}'.trim()),
          if ((it.serialNumber ?? '').isNotEmpty)
            DetailRow('Nº de série', it.serialNumber!),
          if (it.notes.isNotEmpty) DetailRow('Observações', it.notes),
          const SizedBox(height: 16),
          _FieldValuesView(itemId: it.id),
          const SizedBox(height: 16),
          if (children.isNotEmpty) ...[
            Text('Subitens', style: Theme.of(context).textTheme.titleSmall),
            for (final c in children)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(c.name),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/items/${c.id}'),
              ),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Novo subitem'),
              onPressed: () => context.push(
                '/items/new?clientId=${it.clientId}&parentId=${it.id}',
              ),
            ),
          ),
          const Divider(),
          RelatedServiceOrdersSection(itemId: it.id),
          const Divider(),
          ContactSection(scope: ContactScope.item, parentId: it.id),
          const Divider(),
          QrLabelSection(target: QrTarget.item(it.id), entityLabel: it.name),
        ],
      ),
    );
  }

  Widget _form(BuildContext context, LocalItem? existing) {
    final clients = ref.watch(clientListProvider).value ?? const [];
    final types = ref.watch(itemTypeListProvider).value ?? const [];
    final siblings = _clientId == null
        ? const <LocalItem>[]
        : ref
              .watch(itemsByClientProvider(_clientId!))
              .where((i) => i.id != existing?.id)
              .toList();

    final clientName = clients
        .where((c) => c.id == _clientId)
        .map((c) => c.name)
        .join();

    return Scaffold(
      appBar: brandAppBar(
        title: existing == null ? 'Novo item' : 'Editar item',
      ),
      body: SafeArea(
        child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (widget.presetClientId == null && existing == null) ...[
              ClientPickerField(
                clientName: clientName,
                onPick: () async {
                  final id = await pickClient(context);
                  if (id != null) {
                    setState(() {
                      _clientId = id;
                      _parentId = null;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
            ],
            DropdownButtonFormField<String?>(
              key: ValueKey('parent:$_clientId'),
              initialValue: _parentId,
              decoration: const InputDecoration(
                labelText: 'Item-pai (opcional)',
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('— nenhum —')),
                for (final s in siblings)
                  DropdownMenuItem(value: s.id, child: Text(s.name)),
              ],
              onChanged: (v) => setState(() => _parentId = v),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String?>(
              initialValue: _typeId,
              decoration: const InputDecoration(labelText: 'Tipo (opcional)'),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('— sem tipo —'),
                ),
                for (final t in types)
                  DropdownMenuItem(value: t.id, child: Text(t.name)),
              ],
              onChanged: (v) => setState(() => _typeId = v),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Nome'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
            ),
            const SizedBox(height: 16),
            if (_showContact) ...[
              TextFormField(
                controller: _contactPerson,
                decoration: const InputDecoration(labelText: 'Contato'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Telefone'),
              ),
              const SizedBox(height: 16),
            ] else ...[
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _showContact = true),
                  icon: const Icon(Icons.person_add_alt_1_outlined),
                  label: const Text('Adicionar contato'),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (_showAddress) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Endereço',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _postalCode,
                decoration: const InputDecoration(labelText: 'CEP'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _street,
                decoration: const InputDecoration(labelText: 'Logradouro'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _number,
                decoration: const InputDecoration(labelText: 'Número'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _district,
                decoration: const InputDecoration(labelText: 'Bairro'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _city,
                decoration: const InputDecoration(labelText: 'Cidade'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _state,
                maxLength: 2,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(labelText: 'UF'),
                validator: (v) =>
                    (v != null && v.isNotEmpty && v.trim().length != 2)
                    ? 'UF tem 2 letras'
                    : null,
              ),
              const SizedBox(height: 16),
            ] else ...[
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _showAddress = true),
                  icon: const Icon(Icons.add_location_alt_outlined),
                  label: const Text('Adicionar endereço'),
                ),
              ),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _notes,
              decoration: const InputDecoration(labelText: 'Observações'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            ItemCustomFieldsForm(
              key: ValueKey('fields:$_typeId'),
              itemTypeId: _typeId,
              initial: _fieldValues,
              onChanged: (v) => _fieldValues = v,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : () => _submit(existing),
              child: Text(_saving ? 'Salvando…' : 'Salvar'),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

class _FieldValuesView extends ConsumerWidget {
  const _FieldValuesView({required this.itemId});
  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final values = ref.watch(itemFieldValuesProvider(itemId)).value ?? const [];
    if (values.isEmpty) return const SizedBox.shrink();
    final defs = {
      for (final d in ref.watch(itemFieldDefListProvider).value ?? const [])
        d.id: d,
    };
    String fmtDate(DateTime d, {required bool withTime}) {
      final l = d.toLocal();
      String p(int n) => n.toString().padLeft(2, '0');
      final date = '${p(l.day)}/${p(l.month)}/${l.year}';
      return withTime ? '$date ${p(l.hour)}:${p(l.minute)}' : date;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final v in values)
          DetailRow(
            defs[v.fieldDefId]?.label ?? 'Campo',
            v.valueText ??
                v.valueNumber?.toString() ??
                (v.valueBoolean != null
                    ? (v.valueBoolean! ? 'Sim' : 'Não')
                    : (v.valueDatetime == null
                          ? ''
                          : fmtDate(
                              v.valueDatetime!,
                              withTime:
                                  defs[v.fieldDefId]?.dataType == 'datetime',
                            ))),
          ),
      ],
    );
  }
}
