import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:servory/core/network/api_exception.dart';
import 'package:servory/core/providers.dart';
import 'package:servory/core/storage/secure_store.dart';
import 'package:servory/features/auth/application/session_controller.dart';
import 'package:servory/features/auth/data/auth_api.dart';

class MockAuthApi extends Mock implements AuthApi {}

class MockSecureStore extends Mock implements SecureStore {}

void main() {
  late MockAuthApi authApi;
  late MockSecureStore store;
  late ProviderContainer container;

  setUp(() {
    authApi = MockAuthApi();
    store = MockSecureStore();

    when(() => store.getOrCreateDeviceId()).thenAnswer((_) async => 'device-1');
    when(() => store.readAccessToken()).thenAnswer((_) async => null);
    when(() => store.readRefreshToken()).thenAnswer((_) async => null);
    when(() => store.readOrganizationId()).thenAnswer((_) async => null);
    when(() => store.readUserId()).thenAnswer((_) async => null);
    when(
      () => store.saveSession(
        accessToken: any(named: 'accessToken'),
        refreshToken: any(named: 'refreshToken'),
        organizationId: any(named: 'organizationId'),
        userId: any(named: 'userId'),
      ),
    ).thenAnswer((_) async {});
    when(() => store.clearSession()).thenAnswer((_) async {});
    when(() => store.saveLastOnlineValidation(any())).thenAnswer((_) async {});

    container = ProviderContainer(
      overrides: [
        authApiProvider.overrideWithValue(authApi),
        secureStoreProvider.overrideWithValue(store),
      ],
    );
    addTearDown(container.dispose);
  });

  test('sem sessão salva, resolve para não-autenticado', () async {
    // dispara o build() (e a restauração assíncrona)
    container.read(sessionControllerProvider);
    await Future<void>.delayed(Duration.zero);

    expect(
      container.read(sessionControllerProvider),
      isA<SessionUnauthenticated>(),
    );
  });

  test('login com sucesso autentica e salva a sessão', () async {
    when(
      () => authApi.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
        deviceId: any(named: 'deviceId'),
        deviceName: any(named: 'deviceName'),
        devicePlatform: any(named: 'devicePlatform'),
      ),
    ).thenAnswer(
      (_) async => const TokenPair(
        accessToken: 'access',
        refreshToken: 'refresh',
        organizationId: 'org-1',
        userId: 'user-1',
      ),
    );

    final notifier = container.read(sessionControllerProvider.notifier);
    await notifier.login(email: 'tech@example.com', password: 'senha123');

    final state = container.read(sessionControllerProvider);
    expect(state, isA<SessionAuthenticated>());
    expect((state as SessionAuthenticated).userId, 'user-1');
    expect(state.organizationId, 'org-1');
    verify(
      () => store.saveSession(
        accessToken: 'access',
        refreshToken: 'refresh',
        organizationId: 'org-1',
        userId: 'user-1',
      ),
    ).called(1);
  });

  test(
    'login com credenciais inválidas mantém não-autenticado e propaga o erro',
    () async {
      when(
        () => authApi.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
          deviceId: any(named: 'deviceId'),
          deviceName: any(named: 'deviceName'),
          devicePlatform: any(named: 'devicePlatform'),
        ),
      ).thenThrow(
        const ApiException(
          code: 'INVALID_CREDENTIALS',
          message: 'invalid',
          statusCode: 401,
        ),
      );

      final notifier = container.read(sessionControllerProvider.notifier);

      await expectLater(
        notifier.login(email: 'tech@example.com', password: 'errada'),
        throwsA(isA<ApiException>()),
      );

      expect(
        container.read(sessionControllerProvider),
        isA<SessionUnauthenticated>(),
      );
      verifyNever(
        () => store.saveSession(
          accessToken: any(named: 'accessToken'),
          refreshToken: any(named: 'refreshToken'),
          organizationId: any(named: 'organizationId'),
          userId: any(named: 'userId'),
        ),
      );
    },
  );

  test('sessão expirada (porta de refresh) limpa a sessão e desloga', () async {
    container.read(sessionControllerProvider);
    await Future<void>.delayed(Duration.zero);

    container.read(sessionExpiredPortProvider).notify();

    expect(
      container.read(sessionControllerProvider),
      isA<SessionUnauthenticated>(),
    );
    verify(() => store.clearSession()).called(1);
  });
}
