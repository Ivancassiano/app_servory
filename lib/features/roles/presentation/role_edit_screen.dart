import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/brand_app_bar.dart';
import '../../me/application/me_provider.dart';
import '../application/roles_provider.dart';
import '../data/roles_api.dart';
import '../domain/permission_components.dart';

/// Cria (`id == 'new'`) ou edita um perfil: nome, descrição e, para cada
/// componente do app, o nível de acesso (Sem acesso / Ver / Editar) com um
/// "Avançado" opcional para campos sensíveis e ações especiais.
///
/// Perfis padrão (`is_system`) abrem só para leitura, com botão "Duplicar".
class RoleEditScreen extends ConsumerStatefulWidget {
  const RoleEditScreen({super.key, required this.roleId});

  final String roleId;

  bool get isNew => roleId == 'new';

  @override
  ConsumerState<RoleEditScreen> createState() => _RoleEditScreenState();
}

class _RoleEditScreenState extends ConsumerState<RoleEditScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _granted = <String>{};
  final _expanded = <String>{};
  bool _seeded = false;
  bool _dirty = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _seed(Role role) {
    if (_seeded) return;
    _nameController.text = role.name;
    _descController.text = role.description;
    _granted
      ..clear()
      ..addAll(role.allowedKeys);
    _seeded = true;
  }

  void _setAccess(ComponentKeys keys, ComponentAccess access) {
    setState(() {
      _granted
        ..removeAll(keys.all)
        ..addAll(keys.keysFor(access));
      _dirty = true;
    });
  }

  void _toggleKey(String key, bool on) {
    setState(() {
      on ? _granted.add(key) : _granted.remove(key);
      _dirty = true;
    });
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Informe o nome do perfil.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    final ctrl = ref.read(rolesControllerProvider);
    try {
      if (widget.isNew) {
        final role = await ctrl.create(
          name: name,
          description: _descController.text.trim(),
          allowKeys: _granted,
        );
        if (!mounted) return;
        context.pushReplacement('/roles/${role.id}');
      } else {
        await ctrl.saveInfo(
          widget.roleId,
          name: name,
          description: _descController.text.trim(),
        );
        await ctrl.savePermissions(widget.roleId, _granted);
        if (!mounted) return;
        setState(() => _dirty = false);
      }
      messenger.showSnackBar(const SnackBar(content: Text('Perfil salvo.')));
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.friendlyMessage);
    } catch (_) {
      if (mounted) setState(() => _error = 'Não foi possível salvar o perfil.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _duplicate(Role source) async {
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final role = await ref
          .read(rolesControllerProvider)
          .create(
            name: '${source.name} (cópia)',
            description: source.description,
            allowKeys: source.allowedKeys,
          );
      if (!mounted) return;
      context.pushReplacement('/roles/${role.id}');
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.friendlyMessage)));
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir perfil'),
        content: const Text('O perfil será removido. Continuar?'),
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
      await ref.read(rolesControllerProvider).delete(widget.roleId);
      if (mounted) context.pop();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.friendlyMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(permissionCatalogProvider);
    final canEdit =
        ref.watch(permissionsProvider).value?.can('role.update') ?? false;

    if (widget.isNew) {
      return catalogAsync.when(
        loading: _scaffoldLoading,
        error: _scaffoldError,
        data: (catalog) => _form(
          catalog: catalog,
          role: null,
          readOnly: false,
        ),
      );
    }

    final roleAsync = ref.watch(roleByIdProvider(widget.roleId));
    return catalogAsync.when(
      loading: _scaffoldLoading,
      error: _scaffoldError,
      data: (catalog) => roleAsync.when(
        loading: _scaffoldLoading,
        error: _scaffoldError,
        data: (role) {
          _seed(role);
          return _form(
            catalog: catalog,
            role: role,
            readOnly: role.isSystem || !canEdit,
          );
        },
      ),
    );
  }

  Widget _scaffoldLoading() => Scaffold(
    appBar: brandAppBar(title: widget.isNew ? 'Novo perfil' : 'Perfil'),
    body: const Center(child: CircularProgressIndicator()),
  );

  Widget _scaffoldError(Object e, StackTrace _) => Scaffold(
    appBar: brandAppBar(title: widget.isNew ? 'Novo perfil' : 'Perfil'),
    body: Center(
      child: Text(e is ApiException ? e.friendlyMessage : '$e'),
    ),
  );

  Widget _form({
    required List<PermissionCatalogEntry> catalog,
    required Role? role,
    required bool readOnly,
  }) {
    return Scaffold(
      appBar: brandAppBar(
        title: widget.isNew ? 'Novo perfil' : (role?.name ?? 'Perfil'),
        actions: [
          if (role != null &&
              !role.isSystem &&
              role.memberCount == 0 &&
              (ref.watch(permissionsProvider).value?.can('role.delete') ??
                  false))
            IconButton(
              tooltip: 'Excluir',
              icon: const Icon(Icons.delete_outline),
              onPressed: _saving ? null : _delete,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          if (readOnly && (role?.isSystem ?? false))
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              color: BrandColor.divider,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Perfil padrão — não pode ser editado. Duplique para '
                    'criar uma versão sua.',
                    style: TextStyle(fontSize: 12.5, height: 1.4),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _saving ? null : () => _duplicate(role!),
                    icon: const Icon(Icons.copy_all_outlined, size: 18),
                    label: const Text('Duplicar perfil'),
                  ),
                ],
              ),
            ),
          TextField(
            controller: _nameController,
            enabled: !readOnly,
            decoration: const InputDecoration(labelText: 'Nome do perfil'),
            onChanged: (_) => _dirty = true,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descController,
            enabled: !readOnly,
            decoration: const InputDecoration(labelText: 'Descrição'),
            onChanged: (_) => _dirty = true,
          ),
          const SizedBox(height: 8),
          for (final group in permComponentGroups) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 20, 0, 4),
              child: Text(group.toUpperCase(), style: BrandText.fieldLabel),
            ),
            for (final c in permComponents.where((c) => c.group == group))
              _ComponentBlock(
                component: c,
                keys: keysOf(c, catalog),
                granted: _granted,
                readOnly: readOnly,
                expanded: _expanded.contains(c.id),
                onAccess: (a) => _setAccess(keysOf(c, catalog), a),
                onToggleKey: _toggleKey,
                onToggleAdvanced: () => setState(
                  () => _expanded.contains(c.id)
                      ? _expanded.remove(c.id)
                      : _expanded.add(c.id),
                ),
              ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          if (!readOnly) ...[
            const SizedBox(height: 24),
            FilledButton(
              onPressed: (_saving || (!widget.isNew && !_dirty)) ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(widget.isNew ? 'Criar perfil' : 'Salvar'),
            ),
          ],
        ],
      ),
    );
  }
}

class _ComponentBlock extends StatelessWidget {
  const _ComponentBlock({
    required this.component,
    required this.keys,
    required this.granted,
    required this.readOnly,
    required this.expanded,
    required this.onAccess,
    required this.onToggleKey,
    required this.onToggleAdvanced,
  });

  final PermComponent component;
  final ComponentKeys keys;
  final Set<String> granted;
  final bool readOnly;
  final bool expanded;
  final ValueChanged<ComponentAccess> onAccess;
  final void Function(String key, bool on) onToggleKey;
  final VoidCallback onToggleAdvanced;

  @override
  Widget build(BuildContext context) {
    final access = accessOf(keys, granted);
    final segments = <ButtonSegment<ComponentAccess>>[
      const ButtonSegment(
        value: ComponentAccess.none,
        label: Text('Sem acesso'),
      ),
      const ButtonSegment(value: ComponentAccess.view, label: Text('Ver')),
      if (keys.hasEdit)
        const ButtonSegment(value: ComponentAccess.edit, label: Text('Editar')),
    ];

    final advancedKeys = [
      ...keys.specialKeys,
      ...keys.fieldReadKeys,
      ...keys.fieldWriteKeys,
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  component.label,
                  style: const TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (access == ComponentAccess.custom)
                Text(
                  'personalizado',
                  style: BrandText.chip.copyWith(color: BrandColor.blue),
                ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              // IgnorePointer (em vez de onSelectionChanged: null) para o
              // segmento selecionado continuar visível nos perfis padrão.
              child: IgnorePointer(
                ignoring: readOnly,
                child: SegmentedButton<ComponentAccess>(
                  segments: segments,
                  selected: access == ComponentAccess.custom
                      ? const {}
                      : {access},
                  emptySelectionAllowed: true,
                  showSelectedIcon: false,
                  onSelectionChanged: (s) => onAccess(s.first),
                ),
              ),
            ),
          ),
          if (advancedKeys.isNotEmpty) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: onToggleAdvanced,
                child: Text(expanded ? 'Ocultar avançado' : 'Avançado'),
              ),
            ),
            if (expanded)
              for (final k in advancedKeys)
                SwitchListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: granted.contains(k),
                  onChanged: readOnly ? null : (v) => onToggleKey(k, v),
                  title: Text(
                    keys.descriptions[k] ?? k,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
          ],
          const Divider(height: 12),
        ],
      ),
    );
  }
}
