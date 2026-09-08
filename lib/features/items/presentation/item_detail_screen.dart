import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/app_database.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/brand_app_bar.dart';
import '../../../core/widgets/detail_view.dart';
import '../../attachments/presentation/photos_section.dart';
import '../../clients/application/clients_provider.dart';
import '../../clients/presentation/client_picker.dart';
import '../../labels/data/qr_mapper.dart';
import '../../labels/presentation/qr_label_section.dart';
import '../../locations/application/locations_provider.dart';
import '../../locations/data/location_mapper.dart';
import '../../locations/presentation/location_picker.dart';
import '../../service_orders/presentation/related_service_orders_section.dart';
import '../application/item_edit_controller.dart';
import '../application/items_provider.dart';
import 'item_custom_fields_form.dart';

/// Detalhe + criação + edição de um item. `itemId == 'new'` = criação.
class ItemDetailScreen extends ConsumerStatefulWidget {
  const ItemDetailScreen({
    super.key,
    required this.itemId,
    this.presetClientId,
    this.presetLocationId,
  });

  final String itemId;
  final String? presetClientId;
  final String? presetLocationId;

  bool get isNew => itemId == 'new';

  @override
  ConsumerState<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends ConsumerState<ItemDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _notes = TextEditingController();

  String? _clientId;
  String? _locationId;
  String? _typeId;
  Map<String, TypedFieldValue> _fieldValues = {};
  bool _seeded = false;
  bool _saving = false;
  bool _viewMode = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _clientId = widget.presetClientId;
    _locationId = widget.presetLocationId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(itemTypeRepositoryProvider).refresh().catchError((_) {});
      ref.read(itemFieldDefRepositoryProvider).refresh().catchError((_) {});
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _seedFrom(LocalItem it) {
    if (_seeded) return;
    _seeded = true;
    _clientId = it.clientId;
    _locationId = it.locationId;
    _typeId = it.itemTypeId;
    _name.text = it.name;
    _notes.text = it.notes;
  }

  ItemFields _collect() => ItemFields(
    name: _name.text.trim(),
    itemTypeId: _typeId,
    locationId: (_locationId ?? '').isEmpty ? null : _locationId,
    notes: _notes.text.trim(),
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
        id = await ctrl.create(clientId: _clientId!, fields: _collect());
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
          setState(() => _viewMode = true);
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

  String? _locationLabel(String? id) {
    if (id == null || id.isEmpty) return null;
    final l = (ref.watch(locationListProvider).value ?? const [])
        .where((x) => x.id == id)
        .firstOrNull;
    if (l == null) return null;
    final addr = locationAddressLine(l);
    if (l.name.isEmpty) return addr.isEmpty ? 'Local' : addr;
    return addr.isEmpty ? l.name : '${l.name} — $addr';
  }

  Widget _view(BuildContext context, LocalItem it) {
    final types = {
      for (final t in ref.watch(itemTypeListProvider).value ?? const [])
        t.id: t.name,
    };
    final loc = (ref.watch(locationListProvider).value ?? const [])
        .where((l) => l.id == it.locationId)
        .firstOrNull;
    final addr = loc == null ? '' : locationAddressLine(loc);

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
          if (loc != null)
            DetailRow('Local', loc.name.isNotEmpty ? loc.name : 'Local'),
          if (addr.isNotEmpty) DetailRow('Endereço', addr),
          if (it.brand.isNotEmpty || it.model.isNotEmpty)
            DetailRow('Marca/Modelo', '${it.brand} ${it.model}'.trim()),
          if ((it.serialNumber ?? '').isNotEmpty)
            DetailRow('Nº de série', it.serialNumber!),
          if (it.notes.isNotEmpty) DetailRow('Observações', it.notes),
          const SizedBox(height: 16),
          _FieldValuesView(itemId: it.id),
          const SizedBox(height: 16),
          Text('Fotos', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          PhotosSection(ownerKind: 'item', ownerId: it.id),
          const Divider(height: 32),
          RelatedServiceOrdersSection(itemId: it.id),
          const Divider(),
          QrLabelSection(target: QrTarget.item(it.id), entityLabel: it.name),
        ],
      ),
    );
  }

  Widget _form(BuildContext context, LocalItem? existing) {
    final clients = ref.watch(clientListProvider).value ?? const [];
    final types = ref.watch(itemTypeListProvider).value ?? const [];
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
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
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
                        _locationId = null;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
              ],
              if (_clientId != null) ...[
                LocationPickerField(
                  locationLabel: _locationLabel(_locationId),
                  onPick: () async {
                    final id = await pickLocation(
                      context,
                      clientId: _clientId!,
                    );
                    if (id != null) setState(() => _locationId = id);
                  },
                ),
                const SizedBox(height: 16),
              ],
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
              if (existing != null)
                TextButton(
                  onPressed: _saving
                      ? null
                      : () => setState(() {
                          _viewMode = true;
                          _seeded = false;
                        }),
                  child: const Text('Cancelar'),
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
