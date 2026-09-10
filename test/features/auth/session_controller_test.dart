import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:servory/core/network/api_exception.dart';
import 'package:servory/core/providers.dart';
import 'package:servory/core/storage/secure_store.dart';
import 'package:servory/features/auth/application/session_controller.dart';
import 'package:servory/features/auth/data/auth_api.dart';

import '../../support/fake_biometric_gate.dart';

class MockAuthApi extends Mock implements AuthApi {}

class MockSecureStore extends Mock implements SecureStore {}

void main() {
  late MockAuthApi authApi;
  late MockSecureStore store;
  late FakeBiometricGate gate;
  late ProviderContainer container;

  setUp(() {
    authApi = MockAuthApi();
    store = MockSecureStore();
    gate = FakeBiometricGate(supported: true);

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
    when(
      () => store.readBiometricLoginEnabled(),
    ).thenAnswer((_) async => false);
    when(() => store.forgetBiometricLogin()).thenAnswer((_) async {});
    when(() => store.readCredentials()).thenAnswer((_) async => null);
    when(() => store.readLastEmail()).thenAnswer((_) async => null);
    when(() => store.saveLastEmail(any())).thenAnswer((_) async {});
    when(
      () => store.setBiometricLoginEnabled(any()),
    ).thenAnswer((_) async {});
    when(
      () => store.saveCredentials(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async {});

    container = ProviderContainer(
      overrides: [
        authApiProvider.overrideWithValue(authApi),
        secureStoreProvider.overrideWithValue(store),
        biometricGateProvider.overrideWithValue(gate),
      ],
    );
    addTearDown(container.dispose);
  });

  void stubLoginOk() {
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
  }

  test('sem sessão salva, resolve para não-autenticado', () async {
    // dispara o build() (e a restauração assíncrona)
    container.read(sessionControllerProvider);
    await Future<void>.delayed(Duration.zero);

    expect(
      container.read(sessionControllerProvider),
      isA<SessionUnauthenticated>(),
    );
  });

  test('bootSplashMinDuration segura o estado em SessionUnknown', () async {
    final held = ProviderContainer(
      overrides: [
        authApiProvider.overrideWithValue(authApi),
        secureStoreProvider.overrideWithValue(store),
        bootSplashMinDurationProvider.overrideWithValue(
          const Duration(milliseconds: 80),
        ),
      ],
    );
    addTearDown(held.dispose);

    held.read(sessionControllerProvider);
    await Future<void>.delayed(Duration.zero);
    // leitura do secure store já resolveu, mas o splash mínimo ainda segura
    expect(held.read(sessionControllerProvider), isA<SessionUnknown>());

    await Future<void>.delayed(const Duration(milliseconds: 120));
    expect(held.read(sessionControllerProvider), isA<SessionUnauthenticated>());
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

  test('login com biometria ligada guarda as credenciais', () async {
    when(
      () => store.readBiometricLoginEnabled(),
    ).thenAnswer((_) async => true);
    stubLoginOk();

    await container
        .read(sessionControllerProvider.notifier)
        .login(email: 'a@b.com', password: 'segredo');

    verify(
      () => store.saveCredentials(email: 'a@b.com', password: 'segredo'),
    ).called(1);
  });

  test('loginWithBiometrics: digital ok + credenciais salvas -> autentica', () async {
    when(() => store.readCredentials()).thenAnswer(
      (_) async => (email: 'a@b.com', password: 'segredo'),
    );
    stubLoginOk();

    final ok = await container
        .read(sessionControllerProvider.notifier)
        .loginWithBiometrics();

    expect(ok, isTrue);
    expect(gate.authCalls, 1);
    expect(
      container.read(sessionControllerProvider),
      isA<SessionAuthenticated>(),
    );
  });

  test('loginWithBiometrics: digital recusada -> false, não autentica', () async {
    gate.authResult = false;
    when(() => store.readCredentials()).thenAnswer(
      (_) async => (email: 'a@b.com', password: 'segredo'),
    );

    final ok = await container
        .read(sessionControllerProvider.notifier)
        .loginWithBiometrics();

    expect(ok, isFalse);
    verifyNever(
      () => authApi.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
        deviceId: any(named: 'deviceId'),
        deviceName: any(named: 'deviceName'),
        devicePlatform: any(named: 'devicePlatform'),
      ),
    );
  });

  test('loginWithBiometrics: sem credenciais salvas -> false', () async {
    final ok = await container
        .read(sessionControllerProvider.notifier)
        .loginWithBiometrics();
    expect(ok, isFalse);
    expect(gate.authCalls, 0);
  });

  test('login guarda o e-mail do último usuário', () async {
    stubLoginOk();

    await container
        .read(sessionControllerProvider.notifier)
        .login(email: 'a@b.com', password: 'segredo');

    verify(() => store.saveLastEmail('a@b.com')).called(1);
  });

  test('forgotPassword e resetPassword só repassam para a API', () async {
    when(
      () => authApi.forgotPassword(email: any(named: 'email')),
    ).thenAnswer((_) async {});
    when(
      () => authApi.resetPassword(
        code: any(named: 'code'),
        newPassword: any(named: 'newPassword'),
      ),
    ).thenAnswer((_) async {});

    final notifier = container.read(sessionControllerProvider.notifier);
    await notifier.forgotPassword('a@b.com');
    await notifier.resetPassword(code: 'ABCD2345', newPassword: 'nova-senha-1');

    verify(() => authApi.forgotPassword(email: 'a@b.com')).called(1);
    verify(
      () => authApi.resetPassword(
        code: 'ABCD2345',
        newPassword: 'nova-senha-1',
      ),
    ).called(1);
    // não autentica — o backend revoga tudo e o usuário loga de novo
    expect(
      container.read(sessionControllerProvider),
      isNot(isA<SessionAuthenticated>()),
    );
  });

  test('logout limpa a sessão mas mantém o login por digital', () async {
    when(() => store.readAccessToken()).thenAnswer((_) async => 'tok');
    when(() => authApi.logout(any())).thenAnswer((_) async {});

    final notifier = container.read(sessionControllerProvider.notifier);
    await notifier.logout();

    verify(() => store.clearSession()).called(1);
    verifyNever(() => store.forgetBiometricLogin());
    // O primeiro consumo devolve true (suprime o auto-prompt logo após "Sair").
    expect(notifier.consumeSkipBiometricPrompt(), isTrue);
    expect(notifier.consumeSkipBiometricPrompt(), isFalse);
  });
}
