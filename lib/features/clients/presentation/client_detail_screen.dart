import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/network/api_exception.dart';
import '../application/client_edit_controller.dart';
import '../application/clients_provider.dart';

/// `clientId == 'new'` é o sentinela de criação (evita uma rota separada
/// no router). `kind` só é escolhido na criação — imutável depois (spec
/// §7.3), então some do formulário na edição.
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
  bool _saving = false;
  String? _error;

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

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final controller = ref.read(clientEditControllerProvider);
      if (widget.isNew) {
        await controller.create(
          kind: _kind,
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
        );
      } else {
        await controller.update(
          clientId: widget.clientId,
          baseVersion: _version,
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
        );
      }
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
    if (!widget.isNew) {
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
          return _buildForm(context, title: client.name);
        },
      );
    }
    return _buildForm(context, title: 'Novo cliente');
  }

  Widget _buildForm(BuildContext context, {required String title}) {
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
  }
}
