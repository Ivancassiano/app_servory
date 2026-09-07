import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/brand_app_bar.dart';
import '../../auth/application/session_controller.dart';
import '../../sync/application/sync_provider.dart';
import '../application/me_provider.dart';
import '../data/me_api.dart';

/// Tela de configurações: identidade/organização, cadastros auxiliares
/// (Empresas, Etiquetas), catálogos de tipos (ordem de serviço / equipamento)
/// e sair. Acessada pelo ícone de engrenagem na home — tira esses itens "de
/// administração" da tela principal, que fica só com o trabalho do dia
/// (ordens, clientes, locais, equipamentos).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identityAsync = ref.watch(identityProvider);
    final syncState = ref.watch(syncRunnerProvider);

    return Scaffold(
      appBar: brandAppBar(title: 'Configurações'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          identityAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  Text(
                    'Não foi possível carregar sua identidade.\n$error',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => ref.invalidate(identityProvider),
                    child: const Text('Tentar de novo'),
                  ),
                ],
              ),
            ),
            data: (identity) => _IdentityCard(identity: identity, sync: syncState),
          ),
          const SizedBox(height: 16),
          _SettingsGroup(
            items: [
              _SettingsItem(Icons.business_outlined, 'Empresas', '/companies'),
              _SettingsItem(
                Icons.qr_code_2_outlined,
                'Etiquetas',
                '/label-batches',
              ),
            ],
          ),
          const _GroupHeader('Catálogos'),
          _SettingsGroup(
            items: [
              _SettingsItem(
                Icons.assignment_outlined,
                'Tipos de ordem de serviço',
                '/type-catalog?kind=service-order',
              ),
              _SettingsItem(
                Icons.category_outlined,
                'Tipos de item',
                '/type-catalog?kind=item',
              ),
              _SettingsItem(
                Icons.tune_outlined,
                'Campos de item',
                '/item-fields',
              ),
            ],
          ),
          const SizedBox(height: 24),
          Material(
            color: BrandColor.surface,
            child: InkWell(
              onTap: () => ref.read(sessionControllerProvider.notifier).logout(),
              child: Container(
                constraints: const BoxConstraints(minHeight: 52),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: const BoxDecoration(
                  border: Border.fromBorderSide(
                    BorderSide(color: BrandColor.border),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.logout, size: 22, color: BrandColor.errorText),
                    SizedBox(width: 14),
                    Text(
                      'Sair',
                      style: TextStyle(
                        fontFamily: 'Space Grotesk',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: BrandColor.errorText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // [item 3 — em avaliação] rodapé de marca. Para remover: apague
          // esta linha e a classe _BrandFooter no fim do arquivo.
          const _BrandFooter(),
        ],
      ),
    );
  }
}

/// [item 3 — em avaliação] Assinatura discreta no rodapé das configurações.
class _BrandFooter extends StatelessWidget {
  const _BrandFooter();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Center(
        child: Text(
          'ServiceReport · Leiano Sistemas · v1.0.0',
          style: BrandText.brandOver.copyWith(
            fontSize: 9.5,
            letterSpacing: 0.5,
            color: BrandColor.textTertiary,
          ),
        ),
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.identity, required this.sync});

  final Identity identity;
  final AsyncValue<void> sync;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => context.push('/me/person'),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      identity.name.isNotEmpty ? identity.name : identity.email,
                      style: const TextStyle(
                        fontFamily: 'Space Grotesk',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: BrandColor.ink,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: BrandColor.onDarkSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                identity.email,
                style: BrandText.listMeta.copyWith(fontSize: 11.5),
              ),
              const Divider(height: 28),
              _InfoRow(label: 'Organização', value: identity.organizationName),
              const SizedBox(height: 6),
              _InfoRow(label: 'Perfil', value: identity.role),
              if (sync.isLoading) ...[
                const SizedBox(height: 16),
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
              ] else if (sync.hasError) ...[
                const SizedBox(height: 16),
                const Text(
                  'Não foi possível sincronizar agora. Os dados salvos '
                  'continuam disponíveis.',
                  style: TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontSize: 12.5,
                    color: BrandColor.errorText,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 8),
      child: Text(label.toUpperCase(), style: BrandText.fieldLabel),
    );
  }
}

class _SettingsItem {
  const _SettingsItem(this.icon, this.label, this.route);
  final IconData icon;
  final String label;
  final String route;
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.items});
  final List<_SettingsItem> items;

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
            _SettingsTile(item: items[i]),
          ],
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({required this.item});
  final _SettingsItem item;

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

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        SizedBox(
          width: 104,
          child: Text(label.toUpperCase(), style: BrandText.fieldLabel),
        ),
        Expanded(
          child: Text(
            value.isNotEmpty ? value : '—',
            style: BrandText.fieldValue,
          ),
        ),
      ],
    );
  }
}
