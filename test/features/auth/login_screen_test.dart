import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:servory/core/providers.dart';
import 'package:servory/core/storage/secure_store.dart';
import 'package:servory/features/auth/data/auth_api.dart';
import 'package:servory/features/auth/presentation/login_screen.dart';

class MockAuthApi extends Mock implements AuthApi {}

class MockSecureStore extends Mock implements SecureStore {}

void main() {
  late MockAuthApi authApi;
  late MockSecureStore store;

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
    when(() => store.saveLastOnlineValidation(any())).thenAnswer((_) async {});
  });

  Widget buildApp() {
    return ProviderScope(
      overrides: [
        authApiProvider.overrideWithValue(authApi),
        secureStoreProvider.overrideWithValue(store),
      ],
      child: const MaterialApp(home: LoginScreen()),
    );
  }

  testWidgets('mostra campos de e-mail/senha e o botão Entrar', (tester) async {
    await tester.pumpWidget(buildApp());

    expect(find.text('E-mail'), findsOneWidget);
    expect(find.text('Senha'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Entrar'), findsOneWidget);
  });

  testWidgets('submit com campos vazios mostra validação e não chama o login', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());

    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.pump();

    expect(find.text('Informe o e-mail.'), findsOneWidget);
    expect(find.text('Informe a senha.'), findsOneWidget);
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

  testWidgets('submit com credenciais válidas chama o controller de sessão', (
    tester,
  ) async {
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

    await tester.pumpWidget(buildApp());

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'tech@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'senha123');
    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.pumpAndSettle();

    verify(
      () => authApi.login(
        email: 'tech@example.com',
        password: 'senha123',
        deviceId: 'device-1',
        deviceName: any(named: 'deviceName'),
        devicePlatform: any(named: 'devicePlatform'),
      ),
    ).called(1);
  });
}
