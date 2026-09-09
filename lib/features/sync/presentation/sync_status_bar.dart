import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/connectivity/connectivity_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/application/session_controller.dart';
import '../application/sync_provider.dart';

/// Faixa fina no rodapé, presente em TODAS as telas autenticadas (montada no
/// `builder` do `MaterialApp.router`). Diz se o app está online ou offline e
/// o estado do último sync; o botão à direita força um "atualizar tudo"
/// (push + pull + recarrega fotos/assinaturas e limpa o cache de imagens).
///
/// Fica escondida no login/splash/unlock e enquanto o teclado está aberto.
/// No web não aparece: lá o app roda sempre online e não há banco local nem
/// protocolo de sync (o "atualizar tudo" depende do `SyncEngine`).
class SyncStatusBar extends ConsumerStatefulWidget {
  const SyncStatusBar({super.key});

  @override
  ConsumerState<SyncStatusBar> createState() => _SyncStatusBarState();
}

class _SyncStatusBarState extends ConsumerState<SyncStatusBar> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    // Redesenha a cada 30s só para o "há X min" acompanhar o relógio.
    if (!kIsWeb) {
      _tick = Timer.periodic(const Duration(seconds: 30), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return const SizedBox.shrink();
    final session = ref.watch(sessionControllerProvider);
    if (session is! SessionAuthenticated) return const SizedBox.shrink();
    if (MediaQuery.of(context).viewInsets.bottom > 0) {
      return const SizedBox.shrink();
    }

    // `null` no 1º frame (o stream de conectividade ainda não emitiu) — trata
    // como online pra não piscar "offline" na abertura.
    final online = ref.watch(isOnlineProvider).value ?? true;
    final status = ref.watch(syncRunnerProvider);
    final view = _describe(online: online, status: status);

    return Material(
      color: view.background,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: BrandColor.border)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 30,
            child: Row(
              children: [
                const SizedBox(width: 14),
                Container(width: 8, height: 8, color: view.foreground),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    view.label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'IBM Plex Mono',
                      fontSize: 11,
                      letterSpacing: 0.2,
                      color: view.foreground,
                    ),
                  ),
                ),
                IconButton(
                  iconSize: 18,
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Atualizar tudo',
                  color: view.foreground,
                  onPressed: status.isLoading
                      ? null
                      : () => _refresh(context, ref, online),
                  icon: status.isLoading
                      ? SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(view.foreground),
                          ),
                        )
                      : const Icon(Icons.refresh),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _refresh(BuildContext context, WidgetRef ref, bool online) async {
    final messenger = ScaffoldMessenger.of(context);
    if (!online) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Sem conexão — nada a atualizar agora.')),
      );
      return;
    }
    await ref.read(syncRunnerProvider.notifier).refreshEverything();
    if (ref.read(syncRunnerProvider).hasError) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível atualizar agora. Os dados salvos continuam '
            'disponíveis.',
          ),
        ),
      );
    }
  }

  _BarView _describe({required bool online, required SyncStatus status}) {
    if (!online) {
      return const _BarView(
        background: BrandColor.errorBg,
        foreground: BrandColor.errorText,
        label: 'Offline — mostrando dados salvos',
      );
    }
    if (status.isLoading) {
      return const _BarView(
        background: BrandColor.surface,
        foreground: BrandColor.blue,
        label: 'Sincronizando…',
      );
    }
    if (status.hasError) {
      return const _BarView(
        background: BrandColor.errorBg,
        foreground: BrandColor.errorText,
        label: 'Falha ao sincronizar — toque para atualizar',
      );
    }
    return _BarView(
      background: BrandColor.surface,
      foreground: BrandColor.textTertiary,
      label: 'Online${_since(status.lastSuccessAt)}',
    );
  }

  String _since(DateTime? at) {
    if (at == null) return '';
    final d = DateTime.now().difference(at);
    if (d.inMinutes < 1) return ' · atualizado agora';
    if (d.inMinutes < 60) return ' · há ${d.inMinutes} min';
    if (d.inHours < 24) return ' · há ${d.inHours} h';
    return ' · há ${d.inDays} d';
  }
}

class _BarView {
  const _BarView({
    required this.background,
    required this.foreground,
    required this.label,
  });

  final Color background;
  final Color foreground;
  final String label;
}
