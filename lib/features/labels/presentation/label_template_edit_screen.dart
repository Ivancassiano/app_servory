import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../reference/data/reference_repository.dart';
import '../data/label_template_repository.dart';

/// `templateId == 'new'` é o sentinela de criação. `company_id` só pré-preenche
/// o corpo na criação — depois o texto fica "congelado" (ADR-0017).
class LabelTemplateEditScreen extends ConsumerStatefulWidget {
  const LabelTemplateEditScreen({super.key, required this.templateId});

  final String templateId;
  bool get isNew => templateId == 'new';

  @override
  ConsumerState<LabelTemplateEditScreen> createState() =>
      _LabelTemplateEditScreenState();
}

class _LabelTemplateEditScreenState
    extends ConsumerState<LabelTemplateEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bodyController = TextEditingController();
  String? _companyId;
  int? _version;
  bool _seeded = false;
  bool _saving = false;
  String? _error;

  LabelTemplateRepository get _repo =>
      ref.read(labelTemplateRepositoryProvider);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref
            .read(referenceDataRepositoryProvider)
            .refresh(ReferenceKind.company)
            .ignore();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _seedFrom(LabelTemplate t) {
    if (_seeded) return;
    _nameController.text = t.name;
    _bodyController.text = t.body;
    _companyId = t.companyId;
    _version = t.version;
    _seeded = true;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (widget.isNew) {
        final t = await _repo.create(
          companyId: _companyId,
          name: _nameController.text.trim(),
          body: _bodyController.text.trimRight(),
        );
        if (!mounted) return;
        Navigator.of(context).pop();
        context.push('/label-templates/${t.id}');
      } else {
        await _repo.update(
          id: widget.templateId,
          version: _version,
          companyId: _companyId,
          name: _nameController.text.trim(),
          body: _bodyController.text.trimRight(),
        );
        if (!mounted) return;
        Navigator.of(context).pop();
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.friendlyMessage);
    } catch (_) {
      if (mounted) setState(() => _error = 'Não foi possível salvar.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir modelo?'),
        content: const Text(
          'O modelo é inativado. Folhas já geradas com ele não mudam.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _saving = true);
    try {
      await _repo.delete(widget.templateId);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Não foi possível excluir.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isNew) return _form(context, title: 'Novo modelo');

    final async = ref.watch(labelTemplateListProvider);
    final t = async.value?.where((x) => x.id == widget.templateId).firstOrNull;
    if (async.isLoading && t == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (t == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Modelo não encontrado.')),
      );
    }
    _seedFrom(t);
    return _form(context, title: t.name.isNotEmpty ? t.name : 'Modelo');
  }

  Widget _form(BuildContext context, {required String title}) {
    final companies =
        ref.watch(referenceListProvider(ReferenceKind.company)).value ??
        const <ReferenceItem>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (!widget.isNew)
            IconButton(
              tooltip: 'Excluir',
              icon: const Icon(Icons.delete_outline),
              onPressed: _saving ? null : _delete,
            ),
        ],
      ),
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
                  decoration: const InputDecoration(labelText: 'Nome do modelo'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Informe o nome.'
                      : null,
                ),
                const SizedBox(height: 16),
                if (widget.isNew && companies.isNotEmpty) ...[
                  DropdownButtonFormField<String?>(
                    initialValue: _companyId,
                    decoration: const InputDecoration(
                      labelText: 'Basear na empresa (opcional)',
                      helperText:
                          'Só pré-preenche o texto; depois fica independente.',
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('—')),
                      for (final c in companies)
                        DropdownMenuItem(value: c.id, child: Text(c.label)),
                    ],
                    onChanged: (v) => setState(() => _companyId = v),
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _bodyController,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Texto de complemento',
                    hintText: 'Uma linha por linha da etiqueta',
                    alignLabelWithHint: true,
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Informe o texto.'
                      : null,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
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
  }
}
