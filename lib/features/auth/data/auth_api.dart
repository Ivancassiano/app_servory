import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/providers.dart';

/// Par de tokens devolvido por login/refresh (schema `TokenPair` do
/// OpenAPI). `access_token` dura 10 min por padrão; `refresh_token` é de uso
/// único e rotaciona a cada chamada (spec §16).
class TokenPair {
  const TokenPair({
    required this.accessToken,
    required this.refreshToken,
    required this.organizationId,
    required this.userId,
  });

  factory TokenPair.fromJson(Map<String, dynamic> json) {
    return TokenPair(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      organizationId: json['organization_id'] as String,
      userId: json['user_id'] as String,
    );
  }

  final String accessToken;
  final String refreshToken;
  final String organizationId;
  final String userId;
}

/// Chamadas de `/v1/auth/*` (servidas pelo `auth-api`, GUIA-FLUTTER.md §2).
class AuthApi {
  AuthApi(this._dio);

  final Dio _dio;

  /// `device.id` é gerado uma vez por instalação e persistido — nunca um
  /// novo UUID a cada login (spec §16.3).
  Future<TokenPair> login({
    required String email,
    required String password,
    required String deviceId,
    required String deviceName,
    required String devicePlatform,
  }) async {
    try {
      final response = await _dio.post(
        '/v1/auth/login',
        data: {
          'email': email,
          'password': password,
          'device': {
            'id': deviceId,
            'name': deviceName,
            'platform': devicePlatform,
          },
        },
      );
      return TokenPair.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Auto-cadastro: cria a organização + conta admin. O login só é liberado
  /// depois de confirmar o e-mail (ver [verifyEmail]) — aqui não volta token.
  Future<void> register({
    required String organizationName,
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      await _dio.post(
        '/v1/auth/register',
        data: {
          'organization_name': organizationName,
          'name': name,
          'email': email,
          'password': password,
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Confirma o e-mail pelo código recebido e já devolve o par de tokens
  /// (o código prova a posse do endereço, então o servidor abre a sessão).
  Future<TokenPair> verifyEmail({
    required String token,
    required String deviceId,
    required String deviceName,
    required String devicePlatform,
  }) async {
    try {
      final response = await _dio.post(
        '/v1/auth/verify-email',
        data: {
          'token': token,
          'device': {
            'id': deviceId,
            'name': deviceName,
            'platform': devicePlatform,
          },
        },
      );
      return TokenPair.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Reenvia o código de confirmação. Resposta sempre 202 — não revela se a
  /// conta existe ou já foi confirmada.
  Future<void> resendVerification({required String email}) async {
    try {
      await _dio.post('/v1/auth/verification/resend', data: {'email': email});
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> logout(String accessToken) async {
    try {
      await _dio.post(
        '/v1/auth/logout',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
    } on DioException catch (e) {
      // Logout é best-effort do lado do cliente: mesmo que a chamada falhe
      // (ex.: sem rede), a sessão local é limpa de qualquer forma.
      if (e.response?.statusCode != 401) rethrow;
    }
  }
}

final authApiProvider = Provider<AuthApi>(
  (ref) => AuthApi(ref.watch(apiClientProvider).authDio),
);
