import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:servory/core/network/auth_interceptor.dart';
import 'package:servory/core/storage/secure_store.dart';

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);
  final Future<ResponseBody> Function(RequestOptions options) handler;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) => handler(options);
}

class MockSecureStore extends Mock implements SecureStore {}

ResponseBody _jsonBody(Map<String, dynamic> data, int status) {
  return ResponseBody.fromString(
    jsonEncode(data),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

ResponseBody _errorBody(String code, int status) {
  return ResponseBody.fromString(
    jsonEncode({
      'error': {'code': code, 'message': 'x', 'request_id': 'r'},
    }),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

void main() {
  late MockSecureStore store;
  late Dio authDio;
  late Dio businessDio;

  setUp(() {
    store = MockSecureStore();

    when(() => store.readAccessToken()).thenAnswer((_) async => 'expired-token');
    when(() => store.readRefreshToken()).thenAnswer((_) async => 'refresh-token');
    when(() => store.readOrganizationId()).thenAnswer((_) async => 'org-1');
    when(() => store.readUserId()).thenAnswer((_) async => 'user-1');
    when(
      () => store.saveSession(
        accessToken: any(named: 'accessToken'),
        refreshToken: any(named: 'refreshToken'),
        organizationId: any(named: 'organizationId'),
        userId: any(named: 'userId'),
      ),
    ).thenAnswer((_) async {});
    when(() => store.clearSession()).thenAnswer((_) async {});

    authDio = Dio(BaseOptions(baseUrl: 'http://auth.test'));
    businessDio = Dio(BaseOptions(baseUrl: 'http://api.test'));
  });

  test('401 dispara refresh e repete a chamada original com o novo token', () async {
    authDio.httpClientAdapter = _FakeAdapter((options) async {
      return _jsonBody({
        'access_token': 'new-token',
        'refresh_token': 'new-refresh',
        'organization_id': 'org-1',
        'user_id': 'user-1',
      }, 200);
    });

    businessDio.interceptors.add(
      AuthInterceptor(authDio: authDio, businessDio: businessDio, store: store),
    );

    var attempt = 0;
    businessDio.httpClientAdapter = _FakeAdapter((options) async {
      attempt++;
      if (attempt == 1) {
        expect(options.headers['Authorization'], 'Bearer expired-token');
        return _errorBody('UNAUTHORIZED', 401);
      }
      expect(options.headers['Authorization'], 'Bearer new-token');
      return _jsonBody({'ok': true}, 200);
    });

    // A partir da 2ª tentativa, o token guardado já é o novo (efeito colateral
    // do refresh feito por este mesmo interceptor).
    when(() => store.readAccessToken()).thenAnswer((_) async {
      return attempt == 0 ? 'expired-token' : 'new-token';
    });

    final response = await businessDio.get<dynamic>('/v1/me');

    expect(response.data['ok'], true);
    expect(attempt, 2);
    verify(
      () => store.saveSession(
        accessToken: 'new-token',
        refreshToken: 'new-refresh',
        organizationId: 'org-1',
        userId: 'user-1',
      ),
    ).called(1);
  });

  test('duas chamadas concorrentes expirando juntas compartilham um único refresh', () async {
    var refreshCalls = 0;
    authDio.httpClientAdapter = _FakeAdapter((options) async {
      refreshCalls++;
      return _jsonBody({
        'access_token': 'new-token',
        'refresh_token': 'new-refresh',
        'organization_id': 'org-1',
        'user_id': 'user-1',
      }, 200);
    });

    businessDio.interceptors.add(
      AuthInterceptor(authDio: authDio, businessDio: businessDio, store: store),
    );

    var attempts = 0;
    businessDio.httpClientAdapter = _FakeAdapter((options) async {
      attempts++;
      final retried = options.extra['servory_retried'] == true;
      if (!retried) return _errorBody('UNAUTHORIZED', 401);
      return _jsonBody({'ok': true}, 200);
    });

    final results = await Future.wait([
      businessDio.get<dynamic>('/v1/a'),
      businessDio.get<dynamic>('/v1/b'),
    ]);

    expect(results.every((r) => r.data['ok'] == true), true);
    expect(refreshCalls, 1);
    expect(attempts, 4); // 2 chamadas originais + 2 repetições
  });

  test('falha no refresh limpa a sessão e chama onSessionExpired', () async {
    authDio.httpClientAdapter = _FakeAdapter((options) async {
      return _errorBody('INVALID_REFRESH_TOKEN', 401);
    });

    var sessionExpiredCalled = false;
    businessDio.interceptors.add(
      AuthInterceptor(
        authDio: authDio,
        businessDio: businessDio,
        store: store,
        onSessionExpired: () => sessionExpiredCalled = true,
      ),
    );
    businessDio.httpClientAdapter = _FakeAdapter((options) async {
      return _errorBody('UNAUTHORIZED', 401);
    });

    await expectLater(businessDio.get<dynamic>('/v1/me'), throwsA(isA<DioException>()));

    expect(sessionExpiredCalled, true);
    verify(() => store.clearSession()).called(1);
  });
}
