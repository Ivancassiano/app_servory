import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/me_api.dart';

MeApi _meApi(Ref ref) => MeApi(ref.watch(apiClientProvider).businessDio);

/// Identidade do ator autenticado. Refeita a cada login (o `family`/`autoDispose`
/// não são necessários ainda nesta fundação — sem múltiplas sessões
/// simultâneas em tela).
final identityProvider = FutureProvider<Identity>((ref) => _meApi(ref).getMe());

/// Permissões efetivas — só para decorar a UI (spec §17.4).
final permissionsProvider = FutureProvider<PermissionSet>((ref) => _meApi(ref).getPermissions());
