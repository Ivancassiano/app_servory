import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/brand_app_bar.dart';
import '../../me/application/me_provider.dart';
import '../../roles/application/roles_provider.dart';
import '../../roles/domain/permission_components.dart';
import '../application/members_provider.dart';

/// Exceções de permissão de um usuário: por componente, força um nível acima
/// do que o perfil dá (ou "herdar do perfil" = sem exceção). Usa a mesma
/// grade da tela de perfis.
class MemberOverridesScreen extends ConsumerStatefulWidget {
  const MemberOverridesScreen({
    super.key,
    required this.userId,
    this.memberName,
  });

  final String userId;
  final String? memberName;

  @override
  ConsumerState<MemberOverridesScreen> createState() =>
      _MemberOverridesScreenState();
}

class _MemberOverridesScreenState extends ConsumerState<MemberOverridesScreen> {
  final _overrides = <String, String>{};
  bool _seeded = false;
  bool _dirty = false;
  bool _saving = false;
  String? _error;

  void _seed(Map<String, String> current) {
    if (_seeded) return;
    _overrides
      ..clear()
      ..addAll(current);
    _seeded = true;
  }

  void _setAccess(ComponentKeys keys, OverrideAccess access) {
    setState(() {
      for (final k in keys.all) {
        _overrides.remove(k);
      }
      _overrides.addAll(overrideMapFor(keys, access));
      _dirty = true;
    });
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(membersControllerProvider)
          .saveOverrides(widget.userId, _overrides);
      if (!mounted) return;
      setState(() => _dirty = false);
      messenger.showSnackBar(
        const SnackBar(content: Text('Exceções salvas.')),
      );
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.friendlyMessage);
    } catch (_) {
      if (mounted) setState(() => _error = 'Não foi possível salvar.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(permissionCatalogProvider);
    final overridesAsync = ref.watch(memberOverridesProvider(widget.userId));
    final canEdit =
        ref.watch(permissionsProvider).value?.can('permission_override.write') ??
        false;

    final title = (widget.memberName?.isNotEmpty ?? false)
        ? widget.memberName!
        : 'Exceções';

    return Scaffold(
      appBar: brandAppBar(title: title, subtitle: 'Exceções de permissão'),
      body: catalogAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(e is ApiException ? e.friendlyMessage : '$e'),
        ),
        data: (catalog) => overridesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Text(e is ApiException ? e.friendlyMessage : '$e'),
          ),
          data: (current) {
            _seed(current);
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                const Text(
                  'A exceção vale para este usuário e vence o que o perfil '
                  'define. "Herdar do perfil" remove a exceção.',
                  style: TextStyle(fontSize: 12.5, height: 1.4),
                ),
                for (final group in permComponentGroups) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 20, 0, 4),
                    child: Text(
                      group.toUpperCase(),
                      style: BrandText.fieldLabel,
                    ),
                  ),
                  for (final c in permComponents.where((c) => c.group == group))
                    _OverrideBlock(
                      component: c,
                      keys: keysOf(c, catalog),
                      overrides: _overrides,
                      readOnly: !canEdit,
                      onAccess: (a) => _setAccess(keysOf(c, catalog), a),
                    ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
                if (canEdit) ...[
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: (_saving || !_dirty) ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Salvar exceções'),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _OverrideBlock extends StatelessWidget {
  const _OverrideBlock({
    required this.component,
    required this.keys,
    required this.overrides,
    required this.readOnly,
    required this.onAccess,
  });

  final PermComponent component;
  final ComponentKeys keys;
  final Map<String, String> overrides;
  final bool readOnly;
  final ValueChanged<OverrideAccess> onAccess;

  @override
  Widget build(BuildContext context) {
    final access = overrideAccessOf(keys, overrides);
    final segments = <ButtonSegment<OverrideAccess>>[
      const ButtonSegment(
        value: OverrideAccess.inherit,
        label: Text('Herdar'),
      ),
      const ButtonSegment(value: OverrideAccess.none, label: Text('Sem acesso')),
      const ButtonSegment(value: OverrideAccess.view, label: Text('Ver')),
      if (keys.hasEdit)
        const ButtonSegment(value: OverrideAccess.edit, label: Text('Editar')),
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
              if (access == OverrideAccess.custom)
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
              child: IgnorePointer(
                ignoring: readOnly,
                child: SegmentedButton<OverrideAccess>(
                  segments: segments,
                  selected: access == OverrideAccess.custom
                      ? const {}
                      : {access},
                  emptySelectionAllowed: true,
                  showSelectedIcon: false,
                  onSelectionChanged: (s) => onAccess(s.first),
                ),
              ),
            ),
          ),
          const Divider(height: 12),
        ],
      ),
    );
  }
}
