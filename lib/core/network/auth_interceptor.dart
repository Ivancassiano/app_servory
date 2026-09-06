import 'package:dio/dio.dart';

import '../storage/secure_store.dart';

/// Anexa `Authorization: Bearer` a cada chamada e trata a expiração do
/// access token (10 min por padrão, spec §16.1): em qualquer 401, tenta um
/// refresh e repete a chamada original uma única vez — nunca só numa tela
/// específica (GUIA-FLUTTER.md §3.2/3.3).
///
/// Chamadas concorrentes que expiram ao mesmo tempo compartilham o mesmo
/// refresh em voo (evita disparar N refreshes em paralelo, o que rotacionaria
/// o refresh token várias vezes e derrubaria as demais).
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required Dio authDio,
    required Dio businessDio,
    required SecureStore store,
    this.onSessionExpired,
  }) : _authDio = authDio,
       _businessDio = businessDio,
       _store = store;

  final Dio _authDio;
  final SecureStore _store;

  /// O `Dio` de negócio ao qual este interceptor está anexado — passado pelo
  /// `ApiClient` já construído (só ainda sem o interceptor registrado).
  /// Reusado para repetir a chamada original (mesma configuração/adapter/
  /// demais interceptors), em vez de um `Dio` avulso que faria uma
  /// requisição real por fora de tudo isso.
  final Dio _businessDio;

  /// Chamado quando o refresh falha (sessão inválida/revogada/reuso
  /// detectado) — o app deve forçar logout e voltar para a tela de login.
  final void Function()? onSessionExpired;

  Future<bool>? _refreshing;

  static const _retriedFlag = 'servory_retried';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _store.readAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final response = err.response;
    final options = err.requestOptions;
    final alreadyRetried = options.extra[_retriedFlag] == true;

    if (response?.statusCode != 401 || alreadyRetried) {
      handler.next(err);
      return;
    }

    final refreshed = await _refresh();
    if (!refreshed) {
      onSessionExpired?.call();
      handler.next(err);
      return;
    }

    try {
      options.extra[_retriedFlag] = true;
      final response = await _businessDio.fetch<dynamic>(options);
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  /// Garante um único refresh em voo por vez; chamadas concorrentes esperam
  /// o mesmo resultado.
  Future<bool> _refresh() {
    return _refreshing ??= _doRefresh().whenComplete(() {
      _refreshing = null;
    });
  }

  Future<bool> _doRefresh() async {
    final refreshToken = await _store.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;

    try {
      final response = await _authDio.post(
        '/v1/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      final data = response.data as Map;
      final orgId = await _store.readOrganizationId();
      final userId = await _store.readUserId();
      await _store.saveSession(
        accessToken: data['access_token'] as String,
        refreshToken: data['refresh_token'] as String,
        organizationId: (data['organization_id'] as String?) ?? orgId ?? '',
        userId: (data['user_id'] as String?) ?? userId ?? '',
      );
      // Um refresh bem-sucedido é, por definição, uma confirmação com o
      // servidor — reinicia o prazo de 7 dias da sessão offline (spec §18.3).
      await _store.saveLastOnlineValidation(DateTime.now());
      return true;
    } on DioException {
      await _store.clearSession();
      return false;
    }
  }
}
