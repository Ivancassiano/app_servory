import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/app_database.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/brand_app_bar.dart';
import '../../../core/widgets/detail_view.dart';
import '../../attachments/application/attachment_controller.dart';
import '../../attachments/presentation/photos_section.dart';
import '../../attachments/presentation/staged_photos_field.dart';
import '../../clients/application/clients_provider.dart';
import '../../clients/presentation/client_picker.dart';
import '../../items/application/items_provider.dart';
import '../application/location_edit_controller.dart';
import '../application/locations_provider.dart';
import '../data/location_mapper.dart';

/// Detalhe + criação + edição de um local. `id == 'new'` = criação.
class LocationDetailScreen extends ConsumerStatefulWidget {
  const LocationDetailScreen({
    super.key,
    required this.locationId,
    this.presetClientId,
  });

  final String locationId;
  final String? presetClientId;

  bool get isNew => locationId == 'new';

  @override
  ConsumerState<LocationDetailScreen> createState() =>
      _LocationDetailScreenState();
}

class _LocationDetailScreenState extends ConsumerState<LocationDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _postalCode = TextEditingController();
  final _street = TextEditingController();
  final _number = TextEditingController();
  final _complement = TextEditingController();
  final _district = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _notes = TextEditingController();

  String? _clientId;
  int? _version;
  bool _seeded = false;
  bool _viewMode = true;
  bool _saving = false;
  bool _showAddress = false;
  List<StagedPhoto> _stagedPhotos = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _clientId = widget.presetClientId;
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _postalCode,
      _street,
      _number,
      _complement,
      _district,
      _city,
      _state,
      _notes,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _seedFrom(LocalLocation l) {
    if (_seeded) return;
    _seeded = true;
    _clientId = l.clientId;
    _version = l.version;
    _name.text = l.name;
    _postalCode.text = l.postalCode;
    _street.text = l.street;
    _number.text = l.number;
    _complement.text = l.complement;
    _district.text = l.district;
    _city.text = l.city;
    _state.text = l.state;
    _notes.text = l.notes;
    _showAddress = [
      l.postalCode,
      l.street,
      l.number,
      l.complement,
      l.district,
      l.city,
      l.state,
    ].any((s) => s.isNotEmpty);
  }

  LocationFields _collect() => LocationFields(
    name: _name.text.trim(),
    notes: _notes.text.trim(),
    address: _showAddress
        ? LocationAddressInput(
            postalCode: _postalCode.text.trim(),
            street: _street.text.trim(),
            number: _number.text.trim(),
            complement: _complement.text.trim(),
            district: _district.text.trim(),
            city: _city.text.trim(),
            state: _state.text.trim().toUpperCase(),
          )
        : LocationAddressInput.empty,
  );

  Future<void> _submit(LocalLocation? existing) async {
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
      final ctrl = ref.read(locationEditControllerProvider);
      if (existing == null) {
        final id = await ctrl.create(
          clientId: _clientId!,
          fields: _collect(),
        );
        // Fotos escolhidas no cadastro sobem agora que o local tem id.
        final attach = ref.read(attachmentControllerProvider);
        for (final p in _stagedPhotos) {
          try {
            await attach.submitPhoto(
              ownerKind: 'location',
              ownerId: id,
              bytes: p.bytes,
              filename: p.name,
            );
          } catch (_) {
            // uma foto que falha não impede a criação do local
          }
        }
        if (mounted) context.pushReplacement('/locations/$id');
      } else {
        await ctrl.update(
          locationId: existing.id,
          baseVersion: _version,
          fields: _collect(),
        );
        if (mounted) setState(() => _viewMode = true);
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.friendlyMessage);
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
    final async = ref.watch(locationByIdProvider(widget.locationId));
    return async.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: brandAppBar(title: 'Local'),
        body: Center(child: Text('$e')),
      ),
      data: (l) {
        if (l == null) {
          return Scaffold(
            appBar: brandAppBar(title: 'Local'),
            body: const Center(child: Text('Local não encontrado.')),
          );
        }
        _seedFrom(l);
        return _viewMode ? _view(context, l) : _form(context, l);
      },
    );
  }

  Widget _view(BuildContext context, LocalLocation l) {
    final clientName = (ref.watch(clientListProvider).value ?? const [])
        .where((c) => c.id == l.clientId)
        .map((c) => c.name)
        .join();
    final addr = locationAddressLine(l);
    final items = ref.watch(itemsByLocationProvider(l.id));

    return Scaffold(
      appBar: brandAppBar(
        title: l.name.isNotEmpty ? l.name : 'Local',
        subtitle: clientName.isEmpty ? null : clientName,
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
          DetailRow('Cliente', clientName),
          if (addr.isNotEmpty) DetailRow('Endereço', addr),
          if (l.notes.isNotEmpty) DetailRow('Observações', l.notes),
          const SizedBox(height: 16),
          Text('Fotos', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          PhotosSection(ownerKind: 'location', ownerId: l.id),
          const Divider(height: 32),
          Text(
            'Itens neste local',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Nenhum item vinculado.'),
            )
          else
            for (final it in items)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(it.name),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/items/${it.id}'),
              ),
        ],
      ),
    );
  }

  /// Frame com os campos de endereço (aparece ao ligar "Adicionar endereço").
  Widget _addressFrame(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      border: Border.all(color: Theme.of(context).colorScheme.outline),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _number,
                decoration: const InputDecoration(labelText: 'Número'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _complement,
                decoration: const InputDecoration(labelText: 'Complemento'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _district,
          decoration: const InputDecoration(labelText: 'Bairro'),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: _city,
                decoration: const InputDecoration(labelText: 'Cidade'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _state,
                maxLength: 2,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'UF',
                  counterText: '',
                ),
                validator: (v) =>
                    (v != null && v.isNotEmpty && v.trim().length != 2)
                    ? 'UF tem 2 letras'
                    : null,
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _form(BuildContext context, LocalLocation? existing) {
    final clients = ref.watch(clientListProvider).value ?? const [];
    final clientName = clients
        .where((c) => c.id == _clientId)
        .map((c) => c.name)
        .join();

    return Scaffold(
      appBar: brandAppBar(
        title: existing == null ? 'Novo local' : 'Editar local',
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
                    if (id != null) setState(() => _clientId = id);
                  },
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Nome (ex.: Matriz, Galpão 2)',
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      setState(() => _showAddress = !_showAddress),
                  icon: Icon(
                    _showAddress
                        ? Icons.location_off_outlined
                        : Icons.add_location_alt_outlined,
                  ),
                  label: Text(
                    _showAddress ? 'Remover endereço' : 'Adicionar endereço',
                  ),
                ),
              ),
              if (_showAddress) ...[
                const SizedBox(height: 8),
                _addressFrame(context),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _notes,
                decoration: const InputDecoration(labelText: 'Observações'),
                maxLines: 3,
              ),
              if (existing == null) ...[
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Fotos',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                const SizedBox(height: 8),
                StagedPhotosField(
                  photos: _stagedPhotos,
                  onChanged: (p) => setState(() => _stagedPhotos = p),
                ),
              ],
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
