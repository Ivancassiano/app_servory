import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Se o app precisa pedir PIN/biometria de novo antes de mostrar dados
/// (spec §18.3). Só importa quando offline — o `AppRouter` decide se o
/// gate entra em jogo (ver `app_router.dart`); aqui é só o estado
/// "destravado nesta sessão de processo" + reagir a ir para segundo plano.
class AppLockController extends Notifier<bool> with WidgetsBindingObserver {
  @override
  bool build() {
    WidgetsBinding.instance.addObserver(this);
    ref.onDispose(() => WidgetsBinding.instance.removeObserver(this));
    return false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      this.state = false;
    }
  }

  void unlock() => state = true;
}

final appLockControllerProvider = NotifierProvider<AppLockController, bool>(
  AppLockController.new,
);
