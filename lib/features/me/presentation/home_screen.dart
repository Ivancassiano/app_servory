import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/brand_mark.dart';
import '../../labels/data/label_batch_repository.dart';
import '../../service_orders/application/service_orders_provider.dart';
import '../../service_orders/presentation/agenda_card.dart';
import '../../sync/application/sync_provider.dart';

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
    // No web não há banco local: cada tela busca do REST sob demanda.
    if (!kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(syncRunnerProvider.notifier).bootstrapIfNeeded();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final syncState = ref.watch(syncRunnerProvider);
    final orderCount = ref.watch(serviceOrderListProvider).value?.length;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        toolbarHeight: kToolbarHeight + 10,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const BrandIcon(size: 18, onDark: true, mono: true),
                const SizedBox(width: 8),
                Text(
                  'servicereport',
                  style: BrandText.brandWord.copyWith(
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 26),
              child: Text(
                kBrandEndorsement,
                style: BrandText.brandOver.copyWith(
                  fontSize: 8,
                  letterSpacing: 1,
                  color: BrandColor.onDarkSecondary,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Configurações',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          if (syncState.isLoading) ...[
            Row(
              children: [
                Container(width: 8, height: 8, color: BrandColor.blue),
                const SizedBox(width: 8),
                Text(
                  'sincronizando…',
                  style: BrandText.listMeta.copyWith(color: BrandColor.blue),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ] else if (syncState.hasError) ...[
            Container(
              decoration: const BoxDecoration(
                color: BrandColor.errorBg,
                border: Border(
                  left: BorderSide(color: BrandColor.errorBar, width: 3),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: const Text(
                'Não foi possível sincronizar agora. Os dados salvos continuam '
                'disponíveis.',
                style: TextStyle(
                  fontFamily: 'Space Grotesk',
                  fontSize: 12.5,
                  height: 1.4,
                  color: BrandColor.errorText,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          const _QrConflictBanner(),
          const AgendaCard(),
          const SizedBox(height: 4),
          _ShortcutList(
            items: [
              _Shortcut(Icons.task_alt_outlined, 'Tarefas', '/tasks'),
              _Shortcut(
                Icons.assignment_outlined,
                'Ordens de serviço',
                '/service-orders',
                count: orderCount,
              ),
              _Shortcut(Icons.groups_outlined, 'Clientes', '/clients'),
              _Shortcut(Icons.place_outlined, 'Locais', '/locations'),
              _Shortcut(Icons.inventory_2_outlined, 'Itens', '/items'),
            ],
          ),
        ],
      ),
    );
  }
}

/// Pendência de conflito de etiqueta (§9.3) — banner na home só quando há.
class _QrConflictBanner extends ConsumerWidget {
  const _QrConflictBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = ref.watch(qrConflictCountProvider).value ?? 0;
    if (n == 0) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: const BoxDecoration(
        color: BrandColor.errorBg,
        border: Border(left: BorderSide(color: BrandColor.errorBar, width: 3)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            n == 1
                ? '1 etiqueta precisa ser substituída'
                : '$n etiquetas precisam ser substituídas',
            style: const TextStyle(
              fontFamily: 'Space Grotesk',
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: BrandColor.errorText,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Outro dispositivo confirmou o mesmo código primeiro. Abra o '
            'registro e gere uma etiqueta nova.',
            style: TextStyle(
              fontFamily: 'Space Grotesk',
              fontSize: 12,
              height: 1.4,
              color: BrandColor.errorText,
            ),
          ),
        ],
      ),
    );
  }
}

class _Shortcut {
  const _Shortcut(this.icon, this.label, this.route, {this.count});
  final IconData icon;
  final String label;
  final String route;
  final int? count;
}

/// Grade de atalhos no estilo M3 (Android): itens de superfície com 1px de
/// vão `#DCDEE2` entre eles, dentro de uma borda comum.
class _ShortcutList extends StatelessWidget {
  const _ShortcutList({required this.items});
  final List<_Shortcut> items;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border.fromBorderSide(BorderSide(color: BrandColor.border)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(height: 1),
            _ShortcutTile(item: items[i]),
          ],
        ],
      ),
    );
  }
}

class _ShortcutTile extends StatelessWidget {
  const _ShortcutTile({required this.item});
  final _Shortcut item;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: BrandColor.surface,
      child: InkWell(
        onTap: () => context.push(item.route),
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(item.icon, size: 22, color: BrandColor.textTertiary),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  item.label,
                  style: const TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: BrandColor.ink,
                  ),
                ),
              ),
              if (item.count != null && item.count! > 0) ...[
                Text(
                  '${item.count}',
                  style: BrandText.chip.copyWith(
                    color: BrandColor.blue,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 10),
              ],
              const Icon(
                Icons.chevron_right,
                size: 20,
                color: BrandColor.onDarkSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
