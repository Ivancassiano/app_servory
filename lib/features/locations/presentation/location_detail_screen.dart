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
import '../../../core/widgets/form_sheet.dart';
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
  bool _isActive = true;
  List<StagedPhoto> _stagedPhotos = [];

  /// Só na criação: ids de itens a vincular a este local depois que ele
  /// ganhar um id (no `_submit`). Na edição o vínculo é imediato.
  List<String> _stagedItemIds = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _clientId = widget.presetClientId;
  }

  /// Cliente e nome são obrigatórios para salvar.
  bool get _canSave =>
      _clientId != null && _name.text.trim().isNotEmpty;

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
    _isActive = l.isActive;
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

  LocationFields _collect({bool? isActive}) => LocationFields(
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
    isActive: isActive ?? _isActive,
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
              caption: p.caption.trim(),
            );
          } catch (_) {
            // uma foto que falha não impede a criação do local
          }
        }
        // Itens escolhidos no cadastro são vinculados agora (locationId).
        await _linkStagedItems(id);
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

  /// Re-vincula/desvincula um item a este local mexendo no `locationId` do
  /// próprio item (não faz parte do "Salvar" do local — é ação imediata).
  Future<void> _setItemLocation(LocalItem it, String? locationId) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(itemRepositoryProvider)
          .update(
            id: it.id,
            baseVersion: it.version,
            fields: ItemFields(
              name: it.name,
              itemTypeId: it.itemTypeId,
              locationId: locationId,
              notes: it.notes,
            ),
          );
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.friendlyMessage);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Não foi possível atualizar o item.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Vincula ao local recém-criado os itens escolhidos durante o cadastro.
  Future<void> _linkStagedItems(String locationId) async {
    if (_stagedItemIds.isEmpty) return;
    final repo = ref.read(itemRepositoryProvider);
    final all = ref.read(itemListProvider).value ?? const <LocalItem>[];
    for (final itemId in _stagedItemIds) {
      final matches = all.where((i) => i.id == itemId);
      if (matches.isEmpty) continue;
      final it = matches.first;
      try {
        await repo.update(
          id: it.id,
          baseVersion: it.version,
          fields: ItemFields(
            name: it.name,
            itemTypeId: it.itemTypeId,
            locationId: locationId,
            notes: it.notes,
          ),
        );
      } catch (_) {
        // um item que falha não impede a criação do local
      }
    }
  }

  Future<void> _linkItem(
    BuildContext context,
    LocalLocation? existing,
  ) async {
    final clientId = _clientId;
    if (clientId == null) return;
    final picked = await showModalBottomSheet<LocalItem>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _LinkItemSheet(
        clientId: clientId,
        excludeLocationId: existing?.id,
        excludeItemIds: existing == null ? _stagedItemIds : const [],
      ),
    );
    FocusManager.instance.primaryFocus?.unfocus();
    if (picked == null) return;
    if (existing != null) {
      await _setItemLocation(picked, existing.id);
    } else {
      setState(() => _stagedItemIds = [..._stagedItemIds, picked.id]);
    }
  }

  /// Seção "Itens neste local": lista os itens vinculados (com "desvincular")
  /// e permite vincular um existente ou criar um novo. Na criação o vínculo
  /// fica pendente até o "Salvar"; na edição é imediato.
  Widget _linkedItemsSection(BuildContext context, LocalLocation? existing) {
    final List<LocalItem> items;
    if (existing != null) {
      items = ref.watch(itemsByLocationProvider(existing.id));
    } else {
      final all = ref.watch(itemListProvider).value ?? const <LocalItem>[];
      items = [
        for (final id in _stagedItemIds)
          ...all.where((i) => i.id == id),
      ];
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Itens neste local',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        if (_clientId == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Selecione um cliente para vincular itens.'),
          )
        else if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Nenhum item vinculado.'),
          )
        else
          for (final it in items)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.inventory_2_outlined, size: 20),
              title: Text(it.name),
              trailing: IconButton(
                icon: const Icon(Icons.link_off),
                tooltip: 'Desvincular deste local',
                onPressed: _saving
                    ? null
                    : () {
                        if (existing != null) {
                          _setItemLocation(it, null);
                        } else {
                          setState(
                            () => _stagedItemIds = [
                              for (final id in _stagedItemIds)
                                if (id != it.id) id,
                            ],
                          );
                        }
                      },
              ),
            ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: (_saving || _clientId == null)
                    ? null
                    : () => _linkItem(context, existing),
                icon: const Icon(Icons.add_link),
                label: const Text('Vincular item'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _clientId == null
                    ? null
                    : () => context.push(
                        '/items/new?clientId=${_clientId!}'
                        '${existing != null ? '&locationId=${existing.id}' : ''}',
                      ),
                icon: const Icon(Icons.add),
                label: const Text('Novo item'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Inativa/ativa o local (update só do `is_active`, mantendo o resto).
  Future<void> _toggleActive(LocalLocation l) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(locationEditControllerProvider)
          .update(
            locationId: l.id,
            baseVersion: l.version,
            fields: LocationFields(
              name: l.name,
              notes: l.notes,
              address: LocationAddressInput.of(l),
              isActive: !l.isActive,
            ),
          );
      if (mounted) {
        setState(() {
          _isActive = !l.isActive;
          _seeded = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.friendlyMessage);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Não foi possível atualizar. Tente de novo.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDelete(LocalLocation l) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir local?'),
        content: const Text(
          'O local sai do cadastro. Os itens vinculados ficam sem local.',
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
    if (ok != true || !mounted) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(locationEditControllerProvider)
          .delete(locationId: l.id, baseVersion: l.version);
      if (mounted) context.pop();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.friendlyMessage);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Não foi possível excluir. Tente de novo.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Botões "Inativar/Ativar" + "Excluir local" (só num local já salvo).
  Widget _dangerZone(BuildContext context, LocalLocation l) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: _saving ? null : () => _toggleActive(l),
          icon: Icon(
            l.isActive
                ? Icons.pause_circle_outline
                : Icons.play_circle_outline,
          ),
          label: Text(l.isActive ? 'Inativar local' : 'Ativar local'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _saving ? null : () => _confirmDelete(l),
          style: OutlinedButton.styleFrom(
            foregroundColor: theme.colorScheme.error,
          ),
          icon: const Icon(Icons.delete_outline),
          label: const Text('Excluir local'),
        ),
      ],
    );
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
          DetailRow('Situação', l.isActive ? 'Ativo' : 'Inativo'),
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
          const Divider(height: 32),
          _dangerZone(context, l),
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
                decoration: const InputDecoration(labelText: 'UF'),
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
              // Na edição o cliente é imutável — mostra só para referência.
              if (existing != null && clientName.isNotEmpty) ...[
                DetailRow('Cliente', clientName),
                const SizedBox(height: 8),
              ],
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Nome * (ex.: Matriz, Galpão 2)',
                  helperText: 'Obrigatório',
                ),
                onChanged: (_) => setState(() {}),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
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
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Fotos',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              const SizedBox(height: 8),
              if (existing == null)
                StagedPhotosField(
                  photos: _stagedPhotos,
                  onChanged: (p) => setState(() => _stagedPhotos = p),
                )
              else
                PhotosSection(ownerKind: 'location', ownerId: existing.id),
              const Divider(height: 32),
              _linkedItemsSection(context, existing),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: (_saving || !_canSave)
                    ? null
                    : () => _submit(existing),
                child: Text(_saving ? 'Salvando…' : 'Salvar'),
              ),
              if (existing != null) ...[
                TextButton(
                  onPressed: _saving
                      ? null
                      : () => setState(() {
                          _viewMode = true;
                          _seeded = false;
                        }),
                  child: const Text('Cancelar'),
                ),
                const Divider(height: 32),
                _dangerZone(context, existing),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet para vincular um item existente do cliente a este local.
/// Oculta os itens que já estão neste local.
class _LinkItemSheet extends ConsumerStatefulWidget {
  const _LinkItemSheet({
    required this.clientId,
    this.excludeLocationId,
    this.excludeItemIds = const [],
  });

  final String clientId;

  /// Esconde os itens já vinculados a este local (edição).
  final String? excludeLocationId;

  /// Esconde itens já escolhidos (criação, ainda sem local).
  final List<String> excludeItemIds;

  @override
  ConsumerState<_LinkItemSheet> createState() => _LinkItemSheetState();
}

class _LinkItemSheetState extends ConsumerState<_LinkItemSheet> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final items =
        ref
            .watch(itemsByClientProvider(widget.clientId))
            .where(
              (i) =>
                  widget.excludeLocationId == null ||
                  i.locationId != widget.excludeLocationId,
            )
            .where((i) => !widget.excludeItemIds.contains(i.id))
            .where(
              (i) => _q.isEmpty || accentFold(i.name).contains(accentFold(_q)),
            )
            .toList()
          ..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );
    final locNames = <String, String>{
      for (final l in ref.watch(locationListProvider).value ?? const [])
        l.id: l.name,
    };
    return FormSheet(
      title: 'Vincular item',
      children: [
        TextField(
          decoration: const InputDecoration(
            hintText: 'Pesquise um item',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (v) => setState(() => _q = v),
        ),
        const SizedBox(height: 8),
        ...items.map(
          (i) => ListTile(
            dense: true,
            title: Text(i.name),
            subtitle: (locNames[i.locationId] ?? '').isNotEmpty
                ? Text('Hoje em: ${locNames[i.locationId]}')
                : null,
            onTap: () => Navigator.of(context).pop(i),
          ),
        ),
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('Nenhum item disponível para este cliente.'),
          ),
      ],
    );
  }
}
