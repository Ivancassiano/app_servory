import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/app_database.dart';
import '../../../core/network/api_exception.dart';
import '../../labels/data/qr_mapper.dart';
import '../../labels/presentation/qr_label_section.dart';
import '../../locations/application/locations_provider.dart';
import '../application/equipment_edit_controller.dart';
import '../application/equipments_provider.dart';

/// `equipmentId == 'new'` é o sentinela de criação (mesmo padrão de
/// `ClientDetailScreen`). Criar exige escolher local e tipo. `serial_number`
/// e `cost` ficam fora do formulário (campos sensíveis, sem checagem de
/// permissão de escrita no app ainda).
class EquipmentDetailScreen extends ConsumerStatefulWidget {
  const EquipmentDetailScreen({super.key, required this.equipmentId});

  final String equipmentId;
  bool get isNew => equipmentId == 'new';

  @override
  ConsumerState<EquipmentDetailScreen> createState() =>
      _EquipmentDetailScreenState();
}

class _EquipmentDetailScreenState extends ConsumerState<EquipmentDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _notesController = TextEditingController();
  String? _locationId;
  String? _equipmentTypeId;
  int? _version;
  bool _seeded = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.isNew) {
      // Best effort: puxa os tipos do servidor pro seletor (no web/1ª vez).
      Future.microtask(
        () => ref.read(equipmentTypeRepositoryProvider).refresh(),
      ).ignore();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _seedFrom(LocalEquipment equipment) {
    if (_seeded) return;
    _nameController.text = equipment.name;
    _brandController.text = equipment.brand;
    _modelController.text = equipment.model;
    _notesController.text = equipment.notes;
    _locationId = equipment.locationId;
    _equipmentTypeId = equipment.equipmentTypeId;
    _version = equipment.version;
    _seeded = true;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (widget.isNew && (_locationId == null || _equipmentTypeId == null)) {
      setState(() => _error = 'Escolha o local e o tipo.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final controller = ref.read(equipmentEditControllerProvider);
      if (widget.isNew) {
        final id = await controller.create(
          locationId: _locationId!,
          equipmentTypeId: _equipmentTypeId!,
          name: _nameController.text.trim(),
          brand: _brandController.text.trim(),
          model: _modelController.text.trim(),
          notes: _notesController.text.trim(),
        );
        if (!mounted) return;
        Navigator.of(context).pop();
        context.push('/equipments/$id');
      } else {
        await controller.update(
          equipmentId: widget.equipmentId,
          baseVersion: _version,
          name: _nameController.text.trim(),
          brand: _brandController.text.trim(),
          model: _modelController.text.trim(),
          notes: _notesController.text.trim(),
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
    if (widget.isNew) return _form(context, title: 'Novo equipamento');

    final equipmentAsync = ref.watch(equipmentByIdProvider(widget.equipmentId));
    return equipmentAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Erro: $e')),
      ),
      data: (equipment) {
        if (equipment == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Equipamento não encontrado.')),
          );
        }
        _seedFrom(equipment);
        return _form(context, title: equipment.name);
      },
    );
  }

  Widget _form(BuildContext context, {required String title}) {
    final locations = ref.watch(locationListProvider).value ?? const [];
    final types = ref.watch(equipmentTypeListProvider).value ?? const [];

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
                    initialValue: _locationId,
                    decoration: const InputDecoration(labelText: 'Local'),
                    items: [
                      for (final l in locations)
                        DropdownMenuItem(value: l.id, child: Text(l.name)),
                    ],
                    onChanged: (v) => setState(() => _locationId = v),
                    validator: (v) => v == null ? 'Escolha o local.' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _equipmentTypeId,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de equipamento',
                    ),
                    items: [
                      for (final t in types)
                        DropdownMenuItem(value: t.id, child: Text(t.name)),
                    ],
                    onChanged: (v) => setState(() => _equipmentTypeId = v),
                    validator: (v) => v == null ? 'Escolha o tipo.' : null,
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
                  controller: _brandController,
                  decoration: const InputDecoration(labelText: 'Marca'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _modelController,
                  decoration: const InputDecoration(labelText: 'Modelo'),
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
                  QrLabelSection(
                    target: QrTarget.equipment(widget.equipmentId),
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
