import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/brand_app_bar.dart';
import '../../../core/widgets/form_sheet.dart';
import '../../me/application/me_provider.dart';
import '../application/members_provider.dart';
import '../data/members_api.dart';

/// Configurações → Usuários: membros da organização (trocar perfil,
/// suspender/reativar, remover), convites pendentes e o botão de convidar.
/// Sempre online — sem cache local, como o resto de Configurações.
class MembersScreen extends ConsumerWidget {
  const MembersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(orgMembersProvider);
    final invitesAsync = ref.watch(orgInvitationsProvider);
    final rolesAsync = ref.watch(orgRolesProvider);
    final canManage =
        ref.watch(permissionsProvider).value?.can('user.invite') ?? false;
    final myId = ref.watch(identityProvider).value?.userId;

    final roleName = <String, String>{
      for (final r in rolesAsync.value ?? const <OrgRole>[]) r.id: r.name,
    };

    return Scaffold(
      appBar: brandAppBar(title: 'Usuários'),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => _openInvite(context, ref),
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: const Text('Convidar'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async {
          ref
            ..invalidate(orgMembersProvider)
            ..invalidate(orgInvitationsProvider)
            ..invalidate(orgRolesProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          children: [
            const _Header('Membros'),
            membersAsync.when(
              loading: () => const _Loading(),
              error: (e, _) => _Error(
                message: e is ApiException ? e.friendlyMessage : '$e',
                onRetry: () => ref.invalidate(orgMembersProvider),
              ),
              data: (members) => Column(
                children: [
                  for (final m in members)
                    _MemberTile(
                      member: m,
                      roleLabel: m.roleName,
                      isSelf: m.userId == myId,
                      onManage: canManage && m.userId != myId
                          ? () => _memberActions(context, ref, m)
                          : null,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            invitesAsync.maybeWhen(
              data: (invites) => invites.isEmpty
                  ? const SizedBox.shrink()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _Header('Convites pendentes'),
                        for (final inv in invites)
                          _InvitationTile(
                            invitation: inv,
                            roleLabel: roleName[inv.roleId] ?? '—',
                            onRevoke: canManage
                                ? () => _run(
                                    context,
                                    ref,
                                    () => ref
                                        .read(membersControllerProvider)
                                        .revokeInvitation(inv.id),
                                    ok: 'Convite cancelado.',
                                  )
                                : null,
                          ),
                      ],
                    ),
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  // --- ações ---

  Future<void> _openInvite(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _InviteSheet(),
    );
  }

  Future<void> _memberActions(
    BuildContext context,
    WidgetRef ref,
    OrgMember m,
  ) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  m.name.isEmpty ? m.email : m.name,
                  style: Theme.of(ctx).textTheme.titleMedium,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.badge_outlined),
              title: const Text('Trocar perfil'),
              onTap: () => Navigator.pop(ctx, 'role'),
            ),
            ListTile(
              leading: Icon(
                m.suspended ? Icons.play_arrow_outlined : Icons.pause_outlined,
              ),
              title: Text(m.suspended ? 'Reativar acesso' : 'Suspender acesso'),
              onTap: () => Navigator.pop(ctx, 'suspend'),
            ),
            ListTile(
              leading: const Icon(
                Icons.person_remove_outlined,
                color: BrandColor.errorText,
              ),
              title: const Text(
                'Remover da organização',
                style: TextStyle(color: BrandColor.errorText),
              ),
              onTap: () => Navigator.pop(ctx, 'remove'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (action == null || !context.mounted) return;

    switch (action) {
      case 'role':
        final roleId = await _pickRole(context, ref, current: m.roleId);
        if (roleId != null && roleId != m.roleId && context.mounted) {
          await _run(
            context,
            ref,
            () => ref.read(membersControllerProvider).changeRole(m.userId, roleId),
            ok: 'Perfil atualizado.',
          );
        }
      case 'suspend':
        await _run(
          context,
          ref,
          () => ref
              .read(membersControllerProvider)
              .setSuspended(m.userId, suspended: !m.suspended),
          ok: m.suspended ? 'Acesso reativado.' : 'Acesso suspenso.',
        );
      case 'remove':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Remover da organização'),
            content: Text(
              '${m.name.isEmpty ? m.email : m.name} perde o acesso a esta '
              'organização. Os registros criados por essa pessoa continuam.',
            ),
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
        if (confirmed == true && context.mounted) {
          await _run(
            context,
            ref,
            () => ref.read(membersControllerProvider).remove(m.userId),
            ok: 'Membro removido.',
          );
        }
    }
  }

  Future<String?> _pickRole(
    BuildContext context,
    WidgetRef ref, {
    required String current,
  }) {
    final roles = ref.read(orgRolesProvider).value ?? const <OrgRole>[];
    return showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Perfil'),
              ),
            ),
            for (final r in roles)
              ListTile(
                title: Text(r.name),
                trailing: r.id == current
                    ? const Icon(Icons.check, color: BrandColor.blue)
                    : null,
                onTap: () => Navigator.pop(ctx, r.id),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _run(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function() action, {
    required String ok,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      messenger.showSnackBar(SnackBar(content: Text(ok)));
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.friendlyMessage)));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Não foi possível concluir a ação.')),
      );
    }
  }
}

// --- widgets ---

class _Header extends StatelessWidget {
  const _Header(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
    child: Text(label.toUpperCase(), style: BrandText.fieldLabel),
  );
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 24),
    child: Center(child: CircularProgressIndicator()),
  );
}

class _Error extends StatelessWidget {
  const _Error({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Column(
      children: [
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        OutlinedButton(onPressed: onRetry, child: const Text('Tentar de novo')),
      ],
    ),
  );
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.member,
    required this.roleLabel,
    required this.isSelf,
    required this.onManage,
  });

  final OrgMember member;
  final String roleLabel;
  final bool isSelf;
  final VoidCallback? onManage;

  @override
  Widget build(BuildContext context) {
    final title = member.name.isEmpty ? member.email : member.name;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(isSelf ? '$title (você)' : title),
      subtitle: Text(member.email, style: BrandText.listMeta),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (member.suspended) const _Chip('suspenso', danger: true),
          if (member.suspended) const SizedBox(width: 6),
          Text(roleLabel, style: BrandText.chip.copyWith(color: BrandColor.blue)),
          if (onManage != null)
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Icon(Icons.chevron_right, size: 20),
            ),
        ],
      ),
      onTap: onManage,
    );
  }
}

class _InvitationTile extends StatelessWidget {
  const _InvitationTile({
    required this.invitation,
    required this.roleLabel,
    required this.onRevoke,
  });

  final OrgInvitation invitation;
  final String roleLabel;
  final VoidCallback? onRevoke;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(invitation.email),
      subtitle: Text(
        'Perfil $roleLabel · aguardando aceite',
        style: BrandText.listMeta,
      ),
      trailing: onRevoke == null
          ? null
          : TextButton(onPressed: onRevoke, child: const Text('Cancelar')),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label, {this.danger = false});
  final String label;
  final bool danger;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    color: danger ? BrandColor.errorBg : BrandColor.divider,
    child: Text(
      label.toUpperCase(),
      style: BrandText.chip.copyWith(
        color: danger ? BrandColor.errorText : BrandColor.textSecondary,
      ),
    ),
  );
}

/// Folha de convite: e-mail + perfil. O backend envia o código por e-mail;
/// o convidado aceita pela tela "Tenho um convite" no login.
class _InviteSheet extends ConsumerStatefulWidget {
  const _InviteSheet();

  @override
  ConsumerState<_InviteSheet> createState() => _InviteSheetState();
}

class _InviteSheetState extends ConsumerState<_InviteSheet> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  String? _roleId;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit(List<OrgRole> roles) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_roleId == null) {
      setState(() => _error = 'Escolha um perfil.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(membersControllerProvider)
          .invite(email: _emailController.text.trim(), roleId: _roleId!);
      if (!mounted) return;
      Navigator.pop(context);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Convite enviado. O código foi por e-mail.'),
        ),
      );
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.friendlyMessage);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Não foi possível enviar o convite.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final roles = ref.watch(orgRolesProvider).value ?? const <OrgRole>[];
    _roleId ??= roles.where((r) => r.key != 'admin').firstOrNull?.id ??
        roles.firstOrNull?.id;

    return FormSheet(
      title: 'Convidar usuário',
      children: [
        Form(
          key: _formKey,
          child: TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'E-mail'),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Informe o e-mail.';
              if (!v.contains('@')) return 'E-mail inválido.';
              return null;
            },
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _roleId,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Perfil'),
          items: [
            for (final r in roles)
              DropdownMenuItem(value: r.id, child: Text(r.name)),
          ],
          onChanged: (v) => setState(() => _roleId = v),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _busy ? null : () => _submit(roles),
          child: _busy
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Enviar convite'),
        ),
      ],
    );
  }
}
