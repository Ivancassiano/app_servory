import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:servory/app.dart';
import 'package:servory/core/connectivity/connectivity_provider.dart';
import 'package:servory/core/network/api_exception.dart';
import 'package:servory/core/providers.dart';
import 'package:servory/core/storage/secure_store.dart';
import 'package:servory/features/auth/data/auth_api.dart';

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
      () => store.readLastOnlineValidation(),
    ).thenAnswer((_) async => DateTime.now());
  });

  Widget buildApp() {
    return ProviderScope(
      overrides: [
        authApiProvider.overrideWithValue(authApi),
        secureStoreProvider.overrideWithValue(store),
        isOnlineProvider.overrideWith((ref) => Stream.value(true)),
      ],
      child: const ServoryApp(),
    );
  }

  testWidgets(
    'login que falha mantém a mensagem de erro visível na tela (não recria a rota)',
    (tester) async {
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

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Sessão restaurada como não-autenticada → tela de login.
      expect(find.text('E-mail'), findsOneWidget);

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'dev@servory.local',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'errada');
      await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
      await tester.pumpAndSettle();

      // A transição Authenticating → Unauthenticated dispara o
      // refreshListenable do router; antes da correção isso recriava a
      // LoginScreen e a mensagem sumia no frame seguinte.
      expect(find.text('E-mail ou senha inválidos.'), findsOneWidget);
      expect(find.text('E-mail'), findsOneWidget);
    },
  );
}
