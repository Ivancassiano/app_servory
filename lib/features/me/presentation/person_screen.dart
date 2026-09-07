import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../application/person_provider.dart';
import '../data/person_api.dart';

/// Dados pessoais do técnico (`/v1/me/person`). Nome e registro profissional
/// saem no laudo de campo; os demais campos ficam no cadastro para uso
/// futuro (orçamento, etiqueta).
class PersonScreen extends ConsumerStatefulWidget {
  const PersonScreen({super.key});

  @override
  ConsumerState<PersonScreen> createState() => _PersonScreenState();
}

class _PersonScreenState extends ConsumerState<PersonScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _taxId = TextEditingController();
  final _phone = TextEditingController();
  final _registration = TextEditingController();
  final _notes = TextEditingController();
  bool _seeded = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _fullName.dispose();
    _taxId.dispose();
    _phone.dispose();
    _registration.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _seed(Person p) {
    if (_seeded) return;
    _fullName.text = p.fullName;
    _taxId.text = p.taxId;
    _phone.text = p.phone;
    _registration.text = p.professionalRegistration;
    _notes.text = p.notes;
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
          .read(personEditControllerProvider)
          .save(
            fullName: _fullName.text.trim(),
            taxId: _taxId.text.trim(),
            phone: _phone.text.trim(),
            professionalRegistration: _registration.text.trim(),
            notes: _notes.text.trim(),
          );
      if (!mounted) return;
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.friendlyMessage);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Não foi possível salvar. Verifique a conexão.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(myPersonProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Meus dados')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Não foi possível carregar seus dados.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => ref.invalidate(myPersonProvider),
                  child: const Text('Tentar de novo'),
                ),
              ],
            ),
          ),
        ),
        data: (person) {
          _seed(person);
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Nome e registro profissional aparecem no laudo que você '
                      'entrega em campo.',
                      style: BrandText.listMeta.copyWith(fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _fullName,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Nome completo',
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Informe seu nome.'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _registration,
                      decoration: const InputDecoration(
                        labelText: 'Registro profissional (CREA/CFT)',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _taxId,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'CPF'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Telefone'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notes,
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
          );
        },
      ),
    );
  }
}
