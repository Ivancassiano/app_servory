import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../auth/application/session_controller.dart';
import '../data/me_api.dart';

MeApi _meApi(Ref ref) => MeApi(ref.watch(apiClientProvider).businessDio);

/// Identidade do ator autenticado. Refaz quando a sessão muda de conta/
/// organização (login, aceitar convite, trocar de conta) — sem esse `watch`
/// a UI seguiria mostrando o usuário anterior até o app ser reaberto.
final identityProvider = FutureProvider<Identity>((ref) {
  ref.watch(sessionControllerProvider);
  return _meApi(ref).getMe();
});

/// Permissões efetivas — só para decorar a UI (spec §17.4). Também refeitas a
/// cada troca de sessão (perfil diferente = permissões diferentes).
final permissionsProvider = FutureProvider<PermissionSet>((ref) {
  ref.watch(sessionControllerProvider);
  return _meApi(ref).getPermissions();
});
