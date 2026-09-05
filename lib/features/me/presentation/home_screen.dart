import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/application/session_controller.dart';
import '../../sync/application/sync_provider.dart';
import '../application/me_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // 1ª sincronização do dispositivo para esta organização (bootstrap) ou
    // um pull normal se já houver dado local — `bootstrapIfNeeded` decide.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(syncRunnerProvider.notifier).bootstrapIfNeeded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final identityAsync = ref.watch(identityProvider);
    final syncState = ref.watch(syncRunnerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ServiceLog'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () =>
                ref.read(sessionControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: identityAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 12),
                Text(
                  'Não foi possível carregar sua identidade.\n$error',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => ref.invalidate(identityProvider),
                  child: const Text('Tentar de novo'),
                ),
              ],
            ),
          ),
        ),
        data: (identity) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      identity.name.isNotEmpty ? identity.name : identity.email,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      identity.email,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const Divider(height: 32),
                    _InfoRow(
                      label: 'Organização',
                      value: identity.organizationName,
                    ),
                    _InfoRow(label: 'Perfil', value: identity.role),
                    if (syncState.isLoading) ...[
                      const SizedBox(height: 16),
                      const Row(
                        children: [
                          SizedBox(
                            height: 14,
                            width: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('Sincronizando...'),
                        ],
                      ),
                    ] else if (syncState.hasError) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Não foi possível sincronizar agora. Os dados salvos continuam disponíveis.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _ShortcutTile(
              icon: Icons.groups_outlined,
              label: 'Clientes',
              onTap: () => context.push('/clients'),
            ),
            _ShortcutTile(
              icon: Icons.place_outlined,
              label: 'Locais',
              onTap: () => context.push('/locations'),
            ),
            _ShortcutTile(
              icon: Icons.handyman_outlined,
              label: 'Equipamentos',
              onTap: () => context.push('/equipments'),
            ),
            _ShortcutTile(
              icon: Icons.assignment_outlined,
              label: 'Ordens de serviço',
              onTap: () => context.push('/service-orders'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShortcutTile extends StatelessWidget {
  const _ShortcutTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: Theme.of(context).textTheme.labelLarge),
          ),
          Flexible(child: Text(value.isNotEmpty ? value : '—')),
        ],
      ),
    );
  }
}
