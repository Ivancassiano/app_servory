import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/conflict_notice.dart';
import '../../../core/widgets/detail_view.dart';
import '../../contacts/data/contact_repository.dart';
import '../../contacts/presentation/contact_section.dart';
import '../../equipments/presentation/client_equipments_section.dart';
import '../../locations/presentation/client_locations_section.dart';
import '../../labels/data/qr_mapper.dart';
import '../../labels/presentation/qr_label_section.dart';
import '../application/client_edit_controller.dart';
import '../application/clients_provider.dart';

const _kindLabels = {'legal': 'Pessoa jurídica', 'individual': 'Pessoa física'};

/// `clientId == 'new'` é o sentinela de criação (evita uma rota separada
/// no router). Um registro já salvo abre em **leitura**; o lápis no topo
/// liga a edição. `kind` só é escolhido na criação — imutável depois (spec
/// §7.3).
class ClientDetailScreen extends ConsumerStatefulWidget {
  const ClientDetailScreen({super.key, required this.clientId});

  final String clientId;
  bool get isNew => clientId == 'new';

  @override
  ConsumerState<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends ConsumerState<ClientDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String _kind = 'legal';
  int? _version;
  bool _seeded = false;
  bool _editing = false;
  bool _saving = false;
  bool _conflict = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _editing = widget.isNew;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _seedFrom(LocalClient client) {
    if (_seeded) return;
    _nameController.text = client.name;
    _phoneController.text = client.phone;
    _kind = client.kind;
    _version = client.version;
    _seeded = true;
  }

  /// Recarrega do servidor e re-semeia — após conflito de versão ou salvar.
  void _reloadFromServer() {
    ref.invalidate(clientByIdProvider(widget.clientId));
    setState(() {
      _seeded = false;
      _conflict = false;
      _error = null;
    });
  }

  void _cancelEdit() {
    setState(() {
      _editing = false;
      _seeded = false;
      _conflict = false;
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
      _conflict = false;
    });
    try {
      final controller = ref.read(clientEditControllerProvider);
      if (widget.isNew) {
        await controller.create(
          kind: _kind,
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
        );
        if (!mounted) return;
        Navigator.of(context).pop();
        return;
      }
      await controller.update(
        clientId: widget.clientId,
        baseVersion: _version,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
      );
      if (!mounted) return;
      setState(() => _editing = false);
      _reloadFromServer();
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.code == 'VERSION_CONFLICT') {
        setState(() => _conflict = true);
      } else {
        setState(() => _error = e.friendlyMessage);
      }
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
    if (widget.isNew) return _editForm(context, title: 'Novo cliente');

    final clientAsync = ref.watch(clientByIdProvider(widget.clientId));
    return clientAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Erro: $e')),
      ),
      data: (client) {
        if (client == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Cliente não encontrado.')),
          );
        }
        _seedFrom(client);
        return _editing
            ? _editForm(context, title: client.name)
            : _viewMode(context, client);
      },
    );
  }

  // --- leitura ---------------------------------------------------------------

  Widget _viewMode(BuildContext context, LocalClient client) {
    final extras = <Widget>[
      if (client.legalName.isNotEmpty)
        DetailRow('Razão social', client.legalName),
      if (client.taxId.isNotEmpty) DetailRow('CNPJ/CPF', client.taxId),
      if (client.email.isNotEmpty) DetailRow('E-mail', client.email),
      if (client.contactPerson.isNotEmpty)
        DetailRow('Pessoa de contato', client.contactPerson),
      if ((client.internalNotes ?? '').isNotEmpty)
        DetailRow('Observações', client.internalNotes),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(client.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Editar',
            onPressed: () => setState(() => _editing = true),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DetailRow('Tipo', _kindLabels[client.kind] ?? client.kind),
            DetailRow('Telefone', client.phone),
            if (extras.isNotEmpty)
              DetailExpander(title: 'Outros dados', children: extras),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 8),
            ClientLocationsSection(clientId: widget.clientId),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 8),
            ClientEquipmentsSection(clientId: widget.clientId),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 8),
            ContactSection(
              scope: ContactScope.client,
              parentId: widget.clientId,
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 8),
            QrLabelSection(
              target: QrTarget.client(widget.clientId),
              entityLabel: client.name,
            ),
          ],
        ),
      ),
    );
  }

  // --- edição --------------------------------------------------------------

  Widget _editForm(BuildContext context, {required String title}) {
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
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'legal',
                        label: Text('Pessoa jurídica'),
                      ),
                      ButtonSegment(
                        value: 'individual',
                        label: Text('Pessoa física'),
                      ),
                    ],
                    selected: {_kind},
                    onSelectionChanged: (s) => setState(() => _kind = s.first),
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
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Telefone'),
                ),
                if (_conflict) ...[
                  const SizedBox(height: 12),
                  ConflictNotice(onReload: _reloadFromServer),
                ],
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
                if (!widget.isNew)
                  TextButton(
                    onPressed: _saving ? null : _cancelEdit,
                    child: const Text('Cancelar'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
