import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/members_api.dart';

// autoDispose: a lista some da memória ao sair da tela e é sempre buscada
// fresca ao voltar — não faz sentido cachear membros entre navegações, e
// evita mostrar dados da sessão anterior depois de uma troca de conta.
final orgMembersProvider = FutureProvider.autoDispose<List<OrgMember>>(
  (ref) => ref.watch(membersApiProvider).listMembers(),
);

final orgInvitationsProvider = FutureProvider.autoDispose<List<OrgInvitation>>(
  (ref) => ref.watch(membersApiProvider).listInvitations(),
);

final orgRolesProvider = FutureProvider.autoDispose<List<OrgRole>>(
  (ref) => ref.watch(membersApiProvider).listRoles(),
);

/// Ações de escrita da tela de Usuários. Cada uma invalida os providers de
/// leitura afetados para a lista recarregar.
class MembersController {
  MembersController(this._ref);

  final Ref _ref;

  MembersApi get _api => _ref.read(membersApiProvider);

  Future<void> invite({required String email, required String roleId}) async {
    await _api.createInvitation(email: email, roleId: roleId);
    _ref.invalidate(orgInvitationsProvider);
  }

  Future<void> revokeInvitation(String id) async {
    await _api.revokeInvitation(id);
    _ref.invalidate(orgInvitationsProvider);
  }

  Future<void> changeRole(String userId, String roleId) async {
    await _api.updateMember(userId, roleId: roleId);
    _ref.invalidate(orgMembersProvider);
  }

  Future<void> setSuspended(String userId, {required bool suspended}) async {
    await _api.updateMember(
      userId,
      status: suspended ? 'suspended' : 'active',
    );
    _ref.invalidate(orgMembersProvider);
  }

  Future<void> remove(String userId) async {
    await _api.removeMember(userId);
    _ref.invalidate(orgMembersProvider);
  }
}

final membersControllerProvider = Provider<MembersController>(
  MembersController.new,
);
