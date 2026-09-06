import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_exception.dart';
import '../../reference/data/reference_repository.dart';
import '../data/company_repository.dart';

/// `companyId == 'new'` é o sentinela de criação. `kind` só é escolhido na
/// criação — imutável depois. Membros e logo aparecem só depois de salva.
class CompanyDetailScreen extends ConsumerStatefulWidget {
  const CompanyDetailScreen({super.key, required this.companyId});

  final String companyId;
  bool get isNew => companyId == 'new';

  @override
  ConsumerState<CompanyDetailScreen> createState() =>
      _CompanyDetailScreenState();
}

class _CompanyDetailScreenState extends ConsumerState<CompanyDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _legalName = TextEditingController();
  final _taxId = TextEditingController();
  final _taxRegime = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _address = TextEditingController();
  final _notes = TextEditingController();
  String _kind = 'legal';
  String? _personUserId;
  int? _version;
  bool _seeded = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    ref.read(referenceDataRepositoryProvider).refresh(ReferenceKind.orgUser);
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _legalName,
      _taxId,
      _taxRegime,
      _phone,
      _email,
      _address,
      _notes,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _seedFrom(Company c) {
    if (_seeded) return;
    _name.text = c.name;
    _legalName.text = c.legalName;
    _taxId.text = c.taxId;
    _taxRegime.text = c.taxRegime;
    _phone.text = c.phone;
    _email.text = c.email;
    _address.text = c.address;
    _notes.text = c.notes;
    _kind = c.kind;
    _personUserId = c.personUserId;
    _version = c.version;
    _seeded = true;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (widget.isNew && _kind == 'individual' && _personUserId == null) {
      setState(() => _error = 'Escolha a pessoa vinculada.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final repo = ref.read(companyRepositoryProvider);
      if (widget.isNew) {
        await repo.create(
          kind: _kind,
          personUserId: _kind == 'individual' ? _personUserId : null,
          name: _name.text.trim(),
          legalName: _legalName.text.trim(),
          taxId: _taxId.text.trim(),
          taxRegime: _taxRegime.text.trim(),
          phone: _phone.text.trim(),
          email: _email.text.trim(),
          address: _address.text.trim(),
          notes: _notes.text.trim(),
        );
      } else {
        await repo.update(
          widget.companyId,
          version: _version,
          kind: _kind,
          personUserId: _personUserId,
          name: _name.text.trim(),
          legalName: _legalName.text.trim(),
          taxId: _taxId.text.trim(),
          taxRegime: _taxRegime.text.trim(),
          phone: _phone.text.trim(),
          email: _email.text.trim(),
          address: _address.text.trim(),
          notes: _notes.text.trim(),
        );
      }
      // Mantém em dia o seletor de empresa do formulário de ordem.
      await ref
          .read(referenceDataRepositoryProvider)
          .refresh(ReferenceKind.company);
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.friendlyMessage);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Não foi possível salvar. Precisa de conexão.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isNew) return _form(context, title: 'Nova empresa');

    final async = ref.watch(companyByIdProvider(widget.companyId));
    return async.when(
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Erro: $e')),
      ),
      data: (company) {
        if (company == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Empresa não encontrada.')),
          );
        }
        _seedFrom(company);
        return _form(context, title: company.name, company: company);
      },
    );
  }

  Widget _form(BuildContext context, {required String title, Company? company}) {
    final users = ref.watch(referenceListProvider(ReferenceKind.orgUser)).value ??
        const [];

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (!widget.isNew)
            IconButton(
              tooltip: 'Excluir empresa',
              icon: const Icon(Icons.delete_outline),
              onPressed: _confirmDelete,
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
                if (widget.isNew) ...[
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'legal', label: Text('Pessoa jurídica')),
                      ButtonSegment(
                        value: 'individual',
                        label: Text('Profissional'),
                      ),
                    ],
                    selected: {_kind},
                    onSelectionChanged: (s) => setState(() => _kind = s.first),
                  ),
                  const SizedBox(height: 16),
                  if (_kind == 'individual')
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: DropdownButtonFormField<String>(
                        initialValue: _personUserId,
                        decoration: const InputDecoration(
                          labelText: 'Pessoa vinculada',
                        ),
                        items: [
                          for (final u in users)
                            DropdownMenuItem(value: u.id, child: Text(u.label)),
                        ],
                        onChanged: (v) => setState(() => _personUserId = v),
                      ),
                    ),
                ],
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Nome'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Informe o nome.'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _legalName,
                  decoration: const InputDecoration(labelText: 'Razão social'),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _taxId,
                        decoration: const InputDecoration(
                          labelText: 'CNPJ / CPF',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _taxRegime,
                        decoration: const InputDecoration(
                          labelText: 'Regime',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Telefone'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'E-mail'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _address,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Endereço'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notes,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Observações'),
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
                if (!widget.isNew && company != null) ...[
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 8),
                  _LogoSection(company: company),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 8),
                  _MembersSection(companyId: widget.companyId),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir empresa?'),
        content: const Text(
          'Não é possível se houver ordens de serviço vinculadas.',
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
    try {
      await ref.read(companyRepositoryProvider).delete(widget.companyId);
      await ref
          .read(referenceDataRepositoryProvider)
          .refresh(ReferenceKind.company);
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.code == 'CONFLICT' || e.statusCode == 409
                  ? 'Empresa em uso — não pode ser excluída.'
                  : e.friendlyMessage,
            ),
          ),
        );
      }
    }
  }
}

// ---------------------------------------------------------------------------

class _LogoSection extends ConsumerStatefulWidget {
  const _LogoSection({required this.company});
  final Company company;

  @override
  ConsumerState<_LogoSection> createState() => _LogoSectionState();
}

class _LogoSectionState extends ConsumerState<_LogoSection> {
  bool _busy = false;
  Future<String?>? _urlFuture;

  @override
  void initState() {
    super.initState();
    _refreshUrl();
  }

  @override
  void didUpdateWidget(_LogoSection old) {
    super.didUpdateWidget(old);
    if (old.company.logo?.sha256 != widget.company.logo?.sha256) _refreshUrl();
  }

  void _refreshUrl() {
    _urlFuture = widget.company.hasLogo
        ? ref
              .read(companyRepositoryProvider)
              .logoDownloadUrl(widget.company.id)
        : Future.value(null);
  }

  Future<void> _pick() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (file == null || !mounted) return;
    final Uint8List bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() => _busy = true);
    try {
      await ref.read(companyRepositoryProvider).setLogo(
        widget.company.id,
        bytes: bytes,
        filename: file.name,
      );
    } on ApiException catch (e) {
      _snack(e.friendlyMessage);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove() async {
    setState(() => _busy = true);
    try {
      await ref.read(companyRepositoryProvider).deleteLogo(widget.company.id);
    } on ApiException catch (e) {
      _snack(e.friendlyMessage);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String m) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text('Logo', style: Theme.of(context).textTheme.titleSmall),
        ),
        const SizedBox(height: 8),
        if (widget.company.hasLogo)
          FutureBuilder<String?>(
            future: _urlFuture,
            builder: (context, snap) {
              final url = snap.data;
              if (url == null) {
                return const SizedBox(
                  height: 96,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  url,
                  height: 120,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Text('Falha ao exibir o logo.'),
                ),
              );
            },
          )
        else
          const Text('Sem logo.'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _busy ? null : _pick,
                icon: const Icon(Icons.upload_outlined),
                label: Text(widget.company.hasLogo ? 'Trocar' : 'Enviar logo'),
              ),
            ),
            if (widget.company.hasLogo) ...[
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : _remove,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Remover'),
                ),
              ),
            ],
          ],
        ),
        if (_busy)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: LinearProgressIndicator(),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

class _MembersSection extends ConsumerWidget {
  const _MembersSection({required this.companyId});
  final String companyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(companyMembersProvider(companyId));
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text('Pessoas', style: theme.textTheme.titleSmall),
        ),
        const SizedBox(height: 8),
        async.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(),
          ),
          error: (_, _) => Text(
            'Não foi possível carregar as pessoas (precisa de conexão).',
            style: TextStyle(color: theme.colorScheme.error),
          ),
          data: (members) {
            if (members.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Nenhuma pessoa vinculada.'),
              );
            }
            return Column(
              children: [
                for (final m in members)
                  Card(
                    child: ListTile(
                      title: Text(m.name.isNotEmpty ? m.name : m.email),
                      subtitle: Text(m.email),
                      leading: IconButton(
                        tooltip: m.isPrimary
                            ? 'Empresa primária desta pessoa'
                            : 'Marcar como primária',
                        icon: Icon(
                          m.isPrimary ? Icons.star : Icons.star_border,
                        ),
                        onPressed: () => ref
                            .read(companyRepositoryProvider)
                            .setMemberPrimary(
                              companyId,
                              m.userId,
                              isPrimary: !m.isPrimary,
                            ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.person_remove_outlined),
                        onPressed: () => ref
                            .read(companyRepositoryProvider)
                            .removeMember(companyId, m.userId),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _addMember(context, ref),
          icon: const Icon(Icons.person_add_outlined),
          label: const Text('Vincular pessoa'),
        ),
      ],
    );
  }

  Future<void> _addMember(BuildContext context, WidgetRef ref) async {
    final users =
        ref.read(referenceListProvider(ReferenceKind.orgUser)).value ?? const [];
    final current = ref.read(companyMembersProvider(companyId)).value ?? const [];
    final taken = current.map((m) => m.userId).toSet();
    final options = users.where((u) => !taken.contains(u.id)).toList();
    if (options.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Todas as pessoas já estão vinculadas.')),
      );
      return;
    }
    final userId = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Vincular pessoa'),
        children: [
          for (final u in options)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, u.id),
              child: ListTile(title: Text(u.label), subtitle: Text(u.subtitle)),
            ),
        ],
      ),
    );
    if (userId == null) return;
    try {
      await ref
          .read(companyRepositoryProvider)
          .addMember(companyId, userId: userId);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.friendlyMessage)),
        );
      }
    }
  }
}
