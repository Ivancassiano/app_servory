import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../data/contact_repository.dart';

/// Bloco de "Contatos" reaproveitado na tela de cliente e de local.
/// REST-only: listar/editar exige conexão.
class ContactSection extends ConsumerWidget {
  const ContactSection({
    super.key,
    required this.scope,
    required this.parentId,
  });

  final ContactScope scope;
  final String parentId;

  ContactKey get _key => (scope, parentId);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(contactsProvider(_key));
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text('Contatos', style: theme.textTheme.titleSmall),
        ),
        const SizedBox(height: 8),
        async.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(),
          ),
          error: (_, _) => Text(
            'Não foi possível carregar os contatos (precisa de conexão).',
            style: TextStyle(color: theme.colorScheme.error),
          ),
          data: (contacts) {
            if (contacts.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Nenhum contato cadastrado.'),
              );
            }
            return Column(
              children: [
                for (final c in contacts)
                  Card(
                    child: ListTile(
                      title: Row(
                        children: [
                          Flexible(
                            child: Text(
                              c.name.isNotEmpty ? c.name : '(sem nome)',
                            ),
                          ),
                          if (c.isPrimary) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.star, size: 16),
                          ],
                          if (c.isWhatsapp) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.chat_bubble_outline, size: 16),
                          ],
                        ],
                      ),
                      subtitle: Text(
                        [
                          if (c.role.isNotEmpty) c.role,
                          if (c.phone.isNotEmpty) c.phone,
                          if (c.email.isNotEmpty) c.email,
                          if (c.notes.isNotEmpty) c.notes,
                        ].join('\n'),
                      ),
                      isThreeLine: c.notes.isNotEmpty,
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _confirmDelete(context, ref, c),
                      ),
                      onTap: () => _sheet(context, contact: c),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _sheet(context),
          icon: const Icon(Icons.add),
          label: const Text('Adicionar contato'),
        ),
      ],
    );
  }

  Future<void> _sheet(BuildContext context, {Contact? contact}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ContactFormSheet(scope: scope, parentId: parentId, contact: contact),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Contact c,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remover "${c.name.isNotEmpty ? c.name : 'contato'}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(contactRepositoryProvider).delete(_key, c.id);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.friendlyMessage)),
        );
      }
    }
  }
}

class _ContactFormSheet extends ConsumerStatefulWidget {
  const _ContactFormSheet({
    required this.scope,
    required this.parentId,
    this.contact,
  });

  final ContactScope scope;
  final String parentId;
  final Contact? contact;

  @override
  ConsumerState<_ContactFormSheet> createState() => _ContactFormSheetState();
}

class _ContactFormSheetState extends ConsumerState<_ContactFormSheet> {
  late final _nameController = TextEditingController(
    text: widget.contact?.name ?? '',
  );
  late final _roleController = TextEditingController(
    text: widget.contact?.role ?? '',
  );
  late final _phoneController = TextEditingController(
    text: widget.contact?.phone ?? '',
  );
  late final _emailController = TextEditingController(
    text: widget.contact?.email ?? '',
  );
  late final _notesController = TextEditingController(
    text: widget.contact?.notes ?? '',
  );
  late bool _isPrimary = widget.contact?.isPrimary ?? false;
  late bool _isWhatsapp = widget.contact?.isWhatsapp ?? false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  ContactKey get _key => (widget.scope, widget.parentId);

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty &&
        _phoneController.text.trim().isEmpty) {
      setState(() => _error = 'Informe ao menos um nome ou telefone.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final repo = ref.read(contactRepositoryProvider);
      if (widget.contact == null) {
        await repo.add(
          _key,
          name: _nameController.text.trim(),
          role: _roleController.text.trim(),
          phone: _phoneController.text.trim(),
          email: _emailController.text.trim(),
          isPrimary: _isPrimary,
          isWhatsapp: _isWhatsapp,
          notes: _notesController.text.trim(),
        );
      } else {
        await repo.update(
          _key,
          widget.contact!.id,
          version: widget.contact!.version,
          name: _nameController.text.trim(),
          role: _roleController.text.trim(),
          phone: _phoneController.text.trim(),
          email: _emailController.text.trim(),
          isPrimary: _isPrimary,
          isWhatsapp: _isWhatsapp,
          notes: _notesController.text.trim(),
        );
      }
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.friendlyMessage);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Não foi possível salvar. Precisa de conexão.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.contact == null ? 'Novo contato' : 'Editar contato',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nome'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _roleController,
              decoration: const InputDecoration(labelText: 'Cargo / função'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Telefone'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'E-mail'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Observações'),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Contato principal'),
              value: _isPrimary,
              onChanged: (v) => setState(() => _isPrimary = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Tem WhatsApp'),
              value: _isWhatsapp,
              onChanged: (v) => setState(() => _isWhatsapp = v),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 16),
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
    );
  }
}
