import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/rest.dart';
import '../../../core/providers.dart';

/// Uma permissão do catálogo global (`GET /v1/permissions`). As chaves são
/// `{resource}.{action}` (ex.: `client.read`) ou `{resource}.{field}.{read|write}`
/// para permissões de campo (`is_field`).
class PermissionCatalogEntry {
  const PermissionCatalogEntry({
    required this.key,
    required this.resource,
    required this.action,
    required this.isField,
    required this.description,
  });

  factory PermissionCatalogEntry.fromJson(Map<String, dynamic> j) =>
      PermissionCatalogEntry(
        key: j['key'] as String? ?? '',
        resource: j['resource'] as String? ?? '',
        action: j['action'] as String? ?? '',
        isField: j['is_field'] as bool? ?? false,
        description: j['description'] as String? ?? '',
      );

  final String key;
  final String resource;
  final String action;
  final bool isField;
  final String description;
}

class RolePermission {
  const RolePermission({required this.key, required this.effect});

  factory RolePermission.fromJson(Map<String, dynamic> j) => RolePermission(
    key: j['key'] as String? ?? '',
    effect: j['effect'] as String? ?? 'allow',
  );

  Map<String, dynamic> toJson() => {'key': key, 'effect': effect};

  final String key;
  final String effect; // allow | deny
}

class Role {
  const Role({
    required this.id,
    required this.key,
    required this.name,
    required this.description,
    required this.isSystem,
    required this.version,
    required this.memberCount,
    required this.permissions,
  });

  factory Role.fromJson(Map<String, dynamic> j) => Role(
    id: j['id'] as String? ?? '',
    key: j['key'] as String? ?? '',
    name: j['name'] as String? ?? '',
    description: j['description'] as String? ?? '',
    isSystem: j['is_system'] as bool? ?? false,
    version: j['version'] as int? ?? 0,
    memberCount: j['member_count'] as int? ?? 0,
    permissions: ((j['permissions'] as List?) ?? const [])
        .cast<Map<String, dynamic>>()
        .map(RolePermission.fromJson)
        .toList(),
  );

  final String id;
  final String key;
  final String name;
  final String description;
  final bool isSystem;
  final int version;
  final int memberCount;
  final List<RolePermission> permissions;

  /// Só as chaves concedidas (effect allow) — a tela de perfis só monta
  /// allow-list; `deny` fica para exceções por usuário.
  Set<String> get allowedKeys =>
      permissions.where((p) => p.effect == 'allow').map((p) => p.key).toSet();
}

/// Cliente REST de perfis + catálogo de permissões (servicelog-api). Sempre
/// online — sem cache local, como o resto de Configurações.
class RolesApi {
  RolesApi(this._dio);

  final Dio _dio;

  Future<List<PermissionCatalogEntry>> listCatalog() async {
    final r = await restCall(() => _dio.get('/v1/permissions'));
    return ((r.data as Map)['permissions'] as List? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(PermissionCatalogEntry.fromJson)
        .toList();
  }

  Future<List<Role>> listRoles() async {
    final r = await restCall(() => _dio.get('/v1/roles'));
    return ((r.data as Map)['roles'] as List? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(Role.fromJson)
        .toList();
  }

  Future<Role> getRole(String id) async {
    final r = await restCall(() => _dio.get('/v1/roles/$id'));
    return Role.fromJson(r.data as Map<String, dynamic>);
  }

  Future<Role> createRole({
    required String key,
    required String name,
    required String description,
  }) async {
    final r = await restCall(
      () => _dio.post(
        '/v1/roles',
        data: {'key': key, 'name': name, 'description': description},
      ),
    );
    return Role.fromJson(r.data as Map<String, dynamic>);
  }

  Future<void> updateRole(
    String id, {
    required String name,
    required String description,
  }) async {
    await restCall(
      () => _dio.patch(
        '/v1/roles/$id',
        data: {'name': name, 'description': description},
      ),
    );
  }

  Future<void> deleteRole(String id) async {
    await restCall(() => _dio.delete('/v1/roles/$id'));
  }

  Future<void> setRolePermissions(String id, Set<String> allowKeys) async {
    await restCall(
      () => _dio.put(
        '/v1/roles/$id/permissions',
        data: {
          'permissions': [
            for (final k in allowKeys) {'key': k, 'effect': 'allow'},
          ],
        },
      ),
    );
  }
}

final rolesApiProvider = Provider<RolesApi>(
  (ref) => RolesApi(ref.watch(apiClientProvider).businessDio),
);
