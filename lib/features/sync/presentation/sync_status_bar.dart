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
/// Fica escondida no login/splash e enquanto o teclado está aberto.
/// No web não aparece: lá o app roda sempre online e não há banco local nem
/// protocolo de sync (o "atualizar tudo" depende do `SyncEngine`).
class SyncStatusBar extends ConsumerStatefulWidget {
  const SyncStatusBar({super.key});

  @override
  ConsumerState<SyncStatusBar> createState() => _SyncStatusBarState();
}

class _SyncStatusBarState extends ConsumerState<SyncStatusBar>
    with WidgetsBindingObserver {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) return;
    // Redesenha a cada 30s só para o "há X min" acompanhar o relógio.
    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
    // Sincroniza sozinho quando o app volta ao primeiro plano — o Android
    // não avisa antes de uma atualização, então a defesa é subir a fila
    // sempre que dá (ver também o listener de reconexão em [build]).
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _tick?.cancel();
    if (!kIsWeb) WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _autoSync();
  }

  /// Melhor esforço: drena a outbox se estiver online, autenticado e ocioso.
  /// A linha já está persistida, então uma falha aqui só adia o envio.
  void _autoSync() {
    if (kIsWeb || !mounted) return;
    if (ref.read(sessionControllerProvider) is! SessionAuthenticated) return;
    if (!(ref.read(isOnlineProvider).value ?? false)) return;
    if (ref.read(syncRunnerProvider).isLoading) return;
    if (ref.read(pendingSyncCountProvider) == 0) return;
    unawaited(
      ref
          .read(syncRunnerProvider.notifier)
          .runSync()
          .catchError((Object _) {}),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return const SizedBox.shrink();
    final session = ref.watch(sessionControllerProvider);
    if (session is! SessionAuthenticated) return const SizedBox.shrink();
    if (MediaQuery.of(context).viewInsets.bottom > 0) {
      return const SizedBox.shrink();
    }

    // Reconectou (offline → online): tenta drenar a fila na hora.
    ref.listen(isOnlineProvider, (prev, next) {
      final was = prev?.value ?? false;
      final now = next.value ?? false;
      if (!was && now) _autoSync();
    });

    // `null` no 1º frame (o stream de conectividade ainda não emitiu) — trata
    // como online pra não piscar "offline" na abertura.
    final online = ref.watch(isOnlineProvider).value ?? true;
    final status = ref.watch(syncRunnerProvider);
    final pending = ref.watch(pendingSyncCountProvider);
    final view = _describe(online: online, status: status, pending: pending);

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
                  // sem `tooltip:` — esta barra é montada no `builder` do
                  // MaterialApp.router, acima do Navigator, então não há
                  // `Overlay` ancestral para o tooltip (dispara assert em debug
                  // e lança em release ao segurar o botão).
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
      final pending = ref.read(pendingSyncCountProvider);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            pending > 0
                ? 'Sem conexão — suas alterações estão salvas e sobem sozinhas '
                      'quando a internet voltar.'
                : 'Sem conexão — nada a atualizar agora.',
          ),
        ),
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

  _BarView _describe({
    required bool online,
    required SyncStatus status,
    required int pending,
  }) {
    if (!online) {
      return _BarView(
        background: BrandColor.errorBg,
        foreground: BrandColor.errorText,
        label: pending > 0
            ? 'Offline — ${_changes(pending)} p/ enviar'
            : 'Offline — mostrando dados salvos',
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
    if (pending > 0) {
      return _BarView(
        background: BrandColor.warnBg,
        foreground: BrandColor.warnText,
        label: '${_changes(pending)} não enviada${pending == 1 ? '' : 's'} — '
            'toque para enviar',
      );
    }
    return _BarView(
      background: BrandColor.surface,
      foreground: BrandColor.textTertiary,
      label: 'Tudo sincronizado${_since(status.lastSuccessAt)}',
    );
  }

  String _changes(int n) => n == 1 ? '1 alteração' : '$n alterações';

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
