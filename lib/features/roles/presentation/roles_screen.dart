import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/brand_app_bar.dart';
import '../../me/application/me_provider.dart';
import '../application/roles_provider.dart';

/// Configurações → Perfis: lista os perfis da organização. Os 3 padrão
/// (Administrador / Técnico / Visualizador) são só leitura — para customizar,
/// duplica-se e edita a cópia.
class RolesScreen extends ConsumerWidget {
  const RolesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rolesAsync = ref.watch(rolesProvider);
    final canCreate =
        ref.watch(permissionsProvider).value?.can('role.create') ?? false;

    return Scaffold(
      appBar: brandAppBar(title: 'Perfis'),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/roles/new'),
              icon: const Icon(Icons.add),
              label: const Text('Novo perfil'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(rolesProvider),
        child: rolesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                e is ApiException ? e.friendlyMessage : '$e',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Center(
                child: OutlinedButton(
                  onPressed: () => ref.invalidate(rolesProvider),
                  child: const Text('Tentar de novo'),
                ),
              ),
            ],
          ),
          data: (roles) => ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            itemCount: roles.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final r = roles[i];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Row(
                  children: [
                    Flexible(child: Text(r.name)),
                    if (r.isSystem) ...[
                      const SizedBox(width: 8),
                      const _Tag('padrão'),
                    ],
                  ],
                ),
                subtitle: Text(
                  [
                    r.memberCount == 1
                        ? '1 membro'
                        : '${r.memberCount} membros',
                    if (r.description.isNotEmpty) r.description,
                  ].join(' · '),
                  style: BrandText.listMeta,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () => context.push('/roles/${r.id}'),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    color: BrandColor.divider,
    child: Text(
      label.toUpperCase(),
      style: BrandText.chip.copyWith(color: BrandColor.textSecondary),
    ),
  );
}
