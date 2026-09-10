import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/rest.dart';
import '../../../core/providers.dart';

/// Membro da organização (schema `Member` do OpenAPI, `GET /v1/users`).
class OrgMember {
  const OrgMember({
    required this.userId,
    required this.email,
    required this.name,
    required this.userStatus,
    required this.membershipStatus,
    required this.roleId,
    required this.roleKey,
    required this.roleName,
    required this.isDefault,
  });

  factory OrgMember.fromJson(Map<String, dynamic> j) => OrgMember(
    userId: j['user_id'] as String? ?? '',
    email: j['email'] as String? ?? '',
    name: j['name'] as String? ?? '',
    userStatus: j['user_status'] as String? ?? '',
    membershipStatus: j['membership_status'] as String? ?? '',
    roleId: j['role_id'] as String? ?? '',
    roleKey: j['role_key'] as String? ?? '',
    roleName: j['role_name'] as String? ?? '',
    isDefault: j['is_default'] as bool? ?? false,
  );

  final String userId;
  final String email;
  final String name;
  final String userStatus;
  final String membershipStatus;
  final String roleId;
  final String roleKey;
  final String roleName;
  final bool isDefault;

  bool get suspended => membershipStatus == 'suspended';
}

/// Convite pendente (schema `Invitation`).
class OrgInvitation {
  const OrgInvitation({
    required this.id,
    required this.email,
    required this.roleId,
    required this.status,
    required this.expiresAt,
  });

  factory OrgInvitation.fromJson(Map<String, dynamic> j) => OrgInvitation(
    id: j['id'] as String? ?? '',
    email: j['email'] as String? ?? '',
    roleId: j['role_id'] as String? ?? '',
    status: j['status'] as String? ?? '',
    expiresAt: DateTime.tryParse(j['expires_at'] as String? ?? ''),
  );

  final String id;
  final String email;
  final String roleId;
  final String status;
  final DateTime? expiresAt;
}

/// Perfil da organização (schema `Role`) — só o essencial pro seletor.
class OrgRole {
  const OrgRole({required this.id, required this.key, required this.name});

  factory OrgRole.fromJson(Map<String, dynamic> j) => OrgRole(
    id: j['id'] as String? ?? '',
    key: j['key'] as String? ?? '',
    name: j['name'] as String? ?? '',
  );

  final String id;
  final String key;
  final String name;
}

/// Cliente REST de administração de usuários da organização (servido pelo
/// servicelog-api). Sem cache local — sempre online, como o resto do módulo
/// de configurações.
class MembersApi {
  MembersApi(this._dio);

  final Dio _dio;

  Future<List<OrgMember>> listMembers() async {
    final r = await restCall(() => _dio.get('/v1/users'));
    return ((r.data as Map)['users'] as List? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(OrgMember.fromJson)
        .toList();
  }

  Future<void> updateMember(
    String userId, {
    String? roleId,
    String? status,
  }) async {
    await restCall(
      () => _dio.patch(
        '/v1/users/$userId',
        data: {'role_id': ?roleId, 'status': ?status},
      ),
    );
  }

  Future<void> removeMember(String userId) async {
    await restCall(() => _dio.delete('/v1/users/$userId/membership'));
  }

  Future<List<OrgInvitation>> listInvitations() async {
    final r = await restCall(() => _dio.get('/v1/users/invitations'));
    return ((r.data as Map)['invitations'] as List? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(OrgInvitation.fromJson)
        .toList();
  }

  Future<void> createInvitation({
    required String email,
    required String roleId,
  }) async {
    await restCall(
      () => _dio.post(
        '/v1/users/invitations',
        data: {'email': email, 'role_id': roleId},
      ),
    );
  }

  Future<void> revokeInvitation(String id) async {
    await restCall(() => _dio.delete('/v1/users/invitations/$id'));
  }

  Future<List<OrgRole>> listRoles() async {
    final r = await restCall(() => _dio.get('/v1/roles'));
    return ((r.data as Map)['roles'] as List? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(OrgRole.fromJson)
        .toList();
  }

  /// Exceções de permissão de um usuário — `key -> 'allow' | 'deny'`.
  Future<Map<String, String>> getOverrides(String userId) async {
    final r = await restCall(
      () => _dio.get('/v1/users/$userId/permission-overrides'),
    );
    return {
      for (final o in ((r.data as Map)['overrides'] as List? ?? const [])
          .cast<Map<String, dynamic>>())
        o['key'] as String: o['effect'] as String,
    };
  }

  Future<void> setOverrides(
    String userId,
    Map<String, String> overrides,
  ) async {
    // O PUT recebe a lista sob "permissions" (schema PermissionList do
    // OpenAPI); a resposta e o GET devolvem sob "overrides".
    await restCall(
      () => _dio.put(
        '/v1/users/$userId/permission-overrides',
        data: {
          'permissions': [
            for (final e in overrides.entries)
              {'key': e.key, 'effect': e.value},
          ],
        },
      ),
    );
  }
}

final membersApiProvider = Provider<MembersApi>(
  (ref) => MembersApi(ref.watch(apiClientProvider).businessDio),
);
