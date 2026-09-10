import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../auth/application/session_controller.dart';
import '../data/me_api.dart';

MeApi _meApi(Ref ref) => MeApi(ref.watch(apiClientProvider).businessDio);

/// Conta quantas vezes o `permission_version` do token mudou nesta execução.
/// Fica ligado à [PermissionsChangedPort] (o interceptor de auth aciona no
/// refresh); `identityProvider`/`permissionsProvider` observam para recarregar
/// quando um admin mexe no perfil do usuário no meio da sessão.
class _PermissionsEpoch extends Notifier<int> {
  @override
  int build() {
    ref.read(permissionsChangedPortProvider).bind(() => state++);
    return 0;
  }
}

final permissionsEpochProvider = NotifierProvider<_PermissionsEpoch, int>(
  _PermissionsEpoch.new,
);

/// Identidade do ator autenticado. Refaz quando a sessão muda de conta/
/// organização (login, aceitar convite, trocar de conta) ou quando o
/// `permission_version` muda no meio da sessão — sem isso a UI seguiria
/// mostrando o usuário/perfil anterior até o app ser reaberto.
final identityProvider = FutureProvider<Identity>((ref) {
  ref.watch(sessionControllerProvider);
  ref.watch(permissionsEpochProvider);
  return _meApi(ref).getMe();
});

/// Permissões efetivas — só para decorar a UI (spec §17.4). Recarregadas nas
/// mesmas transições da identidade (perfil diferente = permissões diferentes).
final permissionsProvider = FutureProvider<PermissionSet>((ref) {
  ref.watch(sessionControllerProvider);
  ref.watch(permissionsEpochProvider);
  return _meApi(ref).getPermissions();
});
