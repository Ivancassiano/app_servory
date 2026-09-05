import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/app_config.dart';
import 'network/api_client.dart';
import 'storage/secure_store.dart';

/// Providers "de fundação" — compartilhados entre todas as features.
/// Providers específicos de uma feature vivem em
/// `features/<feature>/application/`.

final appConfigProvider = Provider<AppConfig>((ref) => AppConfig.resolve());

final secureStoreProvider = Provider<SecureStore>((ref) => SecureStore());

/// Ponte para quebrar a dependência circular entre [ApiClient] (que precisa
/// avisar quando uma sessão expira) e o controller de sessão (que precisa do
/// [ApiClient] para logar). O controller se registra em [bind] ao ser criado;
/// o interceptor chama [notify] quando um refresh falha de vez.
class SessionExpiredPort {
  void Function()? _listener;
  void bind(void Function() listener) => _listener = listener;
  void notify() => _listener?.call();
}

final sessionExpiredPortProvider = Provider<SessionExpiredPort>((ref) => SessionExpiredPort());

final apiClientProvider = Provider<ApiClient>((ref) {
  final port = ref.watch(sessionExpiredPortProvider);
  return ApiClient(
    config: ref.watch(appConfigProvider),
    store: ref.watch(secureStoreProvider),
    onSessionExpired: port.notify,
  );
});
