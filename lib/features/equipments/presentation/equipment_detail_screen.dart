import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/network/api_exception.dart';
import '../application/equipment_edit_controller.dart';
import '../application/equipments_provider.dart';

/// Só edição — criar um equipamento exige escolher local/tipo, UI que
/// ainda não existe (contexto em `EquipmentEditController`). `serial_number`
/// e `cost` ficam de fora do formulário (campos sensíveis, sem checagem de
/// permissão de escrita no app ainda).
class EquipmentDetailScreen extends ConsumerStatefulWidget {
  const EquipmentDetailScreen({super.key, required this.equipmentId});

  final String equipmentId;

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
  int? _version;
  bool _seeded = false;
  bool _saving = false;
  String? _error;

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
    _version = equipment.version;
    _seeded = true;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(equipmentEditControllerProvider)
          .update(
            equipmentId: widget.equipmentId,
            baseVersion: _version,
            name: _nameController.text.trim(),
            brand: _brandController.text.trim(),
            model: _modelController.text.trim(),
            notes: _notesController.text.trim(),
          );
      if (!mounted) return;
      Navigator.of(context).pop();
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
        return Scaffold(
          appBar: AppBar(title: Text(equipment.name)),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                      decoration: const InputDecoration(
                        labelText: 'Observações',
                      ),
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
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
