import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';

/// Identidade + organização ativa do ator (schema `Identity` do OpenAPI,
/// `GET /v1/me`).
class Identity {
  const Identity({
    required this.userId,
    required this.email,
    required this.name,
    required this.organizationId,
    required this.organizationName,
    required this.role,
    required this.permissionVersion,
  });

  factory Identity.fromJson(Map<String, dynamic> json) {
    return Identity(
      userId: json['user_id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? '',
      organizationId: json['organization_id'] as String? ?? '',
      organizationName: json['organization'] as String? ?? '',
      role: json['role'] as String? ?? '',
      permissionVersion: json['permission_version'] as int? ?? 0,
    );
  }

  final String userId;
  final String email;
  final String name;
  final String organizationId;
  final String organizationName;
  final String role;
  final int permissionVersion;
}

/// Permissões efetivas do ator — decoração de UI apenas, nunca a fonte de
/// verdade de autorização (spec §17.4, GUIA-FLUTTER.md §4). O backend
/// sempre reforça de novo em cada endpoint.
class PermissionSet {
  const PermissionSet({required this.keys, required this.version});

  factory PermissionSet.fromJson(Map<String, dynamic> json) {
    return PermissionSet(
      keys: (json['permissions'] as List? ?? const []).cast<String>().toSet(),
      version: json['permission_version'] as int? ?? 0,
    );
  }

  final Set<String> keys;
  final int version;

  bool can(String key) => keys.contains(key);
}

class MeApi {
  MeApi(this._dio);

  final Dio _dio;

  Future<Identity> getMe() async {
    try {
      final response = await _dio.get('/v1/me');
      return Identity.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<PermissionSet> getPermissions() async {
    try {
      final response = await _dio.get('/v1/me/permissions');
      return PermissionSet.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
