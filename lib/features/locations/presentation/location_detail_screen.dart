import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/app_database.dart';
import '../../../core/network/api_exception.dart';
import '../../clients/application/clients_provider.dart';
import '../../contacts/data/contact_repository.dart';
import '../../contacts/presentation/contact_section.dart';
import '../../labels/data/qr_mapper.dart';
import '../../labels/presentation/qr_label_section.dart';
import '../application/location_edit_controller.dart';
import '../application/locations_provider.dart';
import '../data/location_mapper.dart';

/// `locationId == 'new'` é o sentinela de criação. Criar exige escolher o
/// cliente; o local-pai (hierarquia) é opcional.
class LocationDetailScreen extends ConsumerStatefulWidget {
  const LocationDetailScreen({super.key, required this.locationId});

  final String locationId;
  bool get isNew => locationId == 'new';

  @override
  ConsumerState<LocationDetailScreen> createState() =>
      _LocationDetailScreenState();
}

class _LocationDetailScreenState extends ConsumerState<LocationDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _streetController = TextEditingController();
  final _numberController = TextEditingController();
  final _complementController = TextEditingController();
  final _districtController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  String? _clientId;
  String? _parentLocationId;
  int? _version;
  bool _seeded = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    _postalCodeController.dispose();
    _streetController.dispose();
    _numberController.dispose();
    _complementController.dispose();
    _districtController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  void _seedFrom(LocalLocation location) {
    if (_seeded) return;
    _nameController.text = location.name;
    _contactController.text = location.contactPerson;
    _phoneController.text = location.phone;
    _notesController.text = location.notes;
    _postalCodeController.text = location.postalCode;
    _streetController.text = location.street;
    _numberController.text = location.number;
    _complementController.text = location.complement;
    _districtController.text = location.district;
    _cityController.text = location.city;
    _stateController.text = location.state;
    _clientId = location.clientId;
    _parentLocationId = location.parentLocationId;
    _version = location.version;
    _seeded = true;
  }

  LocationAddressInput get _address => LocationAddressInput(
    postalCode: _postalCodeController.text.trim(),
    street: _streetController.text.trim(),
    number: _numberController.text.trim(),
    complement: _complementController.text.trim(),
    district: _districtController.text.trim(),
    city: _cityController.text.trim(),
    state: _stateController.text.trim().toUpperCase(),
  );

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (widget.isNew && _clientId == null) {
      setState(() => _error = 'Escolha um cliente.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final controller = ref.read(locationEditControllerProvider);
      if (widget.isNew) {
        final id = await controller.create(
          clientId: _clientId!,
          parentLocationId: _parentLocationId,
          name: _nameController.text.trim(),
          contactPerson: _contactController.text.trim(),
          phone: _phoneController.text.trim(),
          notes: _notesController.text.trim(),
          address: _address,
        );
        if (!mounted) return;
        Navigator.of(context).pop();
        context.push('/locations/$id');
      } else {
        await controller.update(
          locationId: widget.locationId,
          baseVersion: _version,
          name: _nameController.text.trim(),
          contactPerson: _contactController.text.trim(),
          phone: _phoneController.text.trim(),
          notes: _notesController.text.trim(),
          address: _address,
        );
        if (!mounted) return;
        Navigator.of(context).pop();
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.friendlyMessage);
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _error =
            'Não foi possível salvar. Os dados ficam pendentes e tentam de novo sozinhos.',
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isNew) return _form(context, title: 'Novo local');

    final locationAsync = ref.watch(locationByIdProvider(widget.locationId));
    return locationAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Erro: $e')),
      ),
      data: (location) {
        if (location == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Local não encontrado.')),
          );
        }
        _seedFrom(location);
        return _form(context, title: location.name);
      },
    );
  }

  Widget _form(BuildContext context, {required String title}) {
    final clients = ref.watch(clientListProvider).value ?? const [];
    final parents = (ref.watch(locationListProvider).value ?? const [])
        .where((l) => l.clientId == _clientId && l.id != widget.locationId)
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.isNew) ...[
                  DropdownButtonFormField<String>(
                    initialValue: _clientId,
                    decoration: const InputDecoration(labelText: 'Cliente'),
                    items: [
                      for (final c in clients)
                        DropdownMenuItem(value: c.id, child: Text(c.name)),
                    ],
                    onChanged: (v) => setState(() {
                      _clientId = v;
                      _parentLocationId = null;
                    }),
                    validator: (v) => v == null ? 'Escolha um cliente.' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String?>(
                    initialValue: parents.any((l) => l.id == _parentLocationId)
                        ? _parentLocationId
                        : null,
                    decoration: const InputDecoration(
                      labelText: 'Local-pai (opcional)',
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('—'),
                      ),
                      for (final l in parents)
                        DropdownMenuItem<String?>(
                          value: l.id,
                          child: Text(l.name),
                        ),
                    ],
                    onChanged: _clientId == null
                        ? null
                        : (v) => setState(() => _parentLocationId = v),
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nome'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Informe o nome.'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _contactController,
                  decoration: const InputDecoration(labelText: 'Contato'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Telefone'),
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Endereço',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _postalCodeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'CEP'),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _streetController,
                        decoration: const InputDecoration(labelText: 'Rua'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _numberController,
                        decoration: const InputDecoration(labelText: 'Número'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _complementController,
                  decoration: const InputDecoration(labelText: 'Complemento'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _districtController,
                  decoration: const InputDecoration(labelText: 'Bairro'),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _cityController,
                        decoration: const InputDecoration(labelText: 'Cidade'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _stateController,
                        maxLength: 2,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'UF',
                          counterText: '',
                        ),
                        validator: (v) {
                          final s = (v ?? '').trim();
                          return s.isNotEmpty && s.length != 2
                              ? 'UF tem 2 letras.'
                              : null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Observações'),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _saving ? null : _submit,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Salvar'),
                ),
                if (!widget.isNew) ...[
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 8),
                  ContactSection(
                    scope: ContactScope.location,
                    parentId: widget.locationId,
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 8),
                  QrLabelSection(
                    target: QrTarget.location(widget.locationId),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
