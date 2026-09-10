import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/app_config.dart';
import 'network/api_client.dart';
import 'security/biometric_gate.dart';
import 'storage/secure_store.dart';

/// Providers "de fundação" — compartilhados entre todas as features.
/// Providers específicos de uma feature vivem em
/// `features/<feature>/application/`.

final appConfigProvider = Provider<AppConfig>((ref) => AppConfig.resolve());

final secureStoreProvider = Provider<SecureStore>((ref) => SecureStore());

final biometricGateProvider = Provider<BiometricGate>(
  (ref) => LocalAuthBiometricGate(),
);

/// Ponte para quebrar a dependência circular entre [ApiClient] (que precisa
/// avisar quando uma sessão expira) e o controller de sessão (que precisa do
/// [ApiClient] para logar). O controller se registra em [bind] ao ser criado;
/// o interceptor chama [notify] quando um refresh falha de vez.
class SessionExpiredPort {
  void Function()? _listener;
  void bind(void Function() listener) => _listener = listener;
  void notify() => _listener?.call();
}

final sessionExpiredPortProvider = Provider<SessionExpiredPort>(
  (ref) => SessionExpiredPort(),
);

/// Ponte para o interceptor avisar que o `permission_version` do token mudou
/// num refresh (o admin trocou o perfil/permissão do usuário no meio da
/// sessão). Quem escuta reavalia `permissionsProvider`/`identityProvider`.
class PermissionsChangedPort {
  void Function()? _listener;
  void bind(void Function() listener) => _listener = listener;
  void notify() => _listener?.call();
}

final permissionsChangedPortProvider = Provider<PermissionsChangedPort>(
  (ref) => PermissionsChangedPort(),
);

final apiClientProvider = Provider<ApiClient>((ref) {
  final expiredPort = ref.watch(sessionExpiredPortProvider);
  final permsPort = ref.watch(permissionsChangedPortProvider);
  return ApiClient(
    config: ref.watch(appConfigProvider),
    store: ref.watch(secureStoreProvider),
    onSessionExpired: expiredPort.notify,
    onPermissionsChanged: permsPort.notify,
  );
});
