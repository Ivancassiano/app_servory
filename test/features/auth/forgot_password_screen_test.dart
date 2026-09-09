import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:servory/core/network/api_exception.dart';
import 'package:servory/core/providers.dart';
import 'package:servory/core/storage/secure_store.dart';
import 'package:servory/features/auth/data/auth_api.dart';
import 'package:servory/features/auth/presentation/forgot_password_screen.dart';

class MockAuthApi extends Mock implements AuthApi {}

class MockSecureStore extends Mock implements SecureStore {}

void main() {
  late MockAuthApi authApi;
  late MockSecureStore store;

  setUp(() {
    authApi = MockAuthApi();
    store = MockSecureStore();
    when(() => store.getOrCreateDeviceId()).thenAnswer((_) async => 'd1');
    when(() => store.readAccessToken()).thenAnswer((_) async => null);
    when(() => store.readRefreshToken()).thenAnswer((_) async => null);
    when(() => store.readOrganizationId()).thenAnswer((_) async => null);
    when(() => store.readUserId()).thenAnswer((_) async => null);
  });

  Widget buildApp() {
    final router = GoRouter(
      initialLocation: '/forgot-password',
      routes: [
        GoRoute(
          path: '/forgot-password',
          builder: (_, _) => const ForgotPasswordScreen(),
        ),
        GoRoute(path: '/login', builder: (_, _) => const Text('LOGIN')),
      ],
    );
    return ProviderScope(
      overrides: [
        authApiProvider.overrideWithValue(authApi),
        secureStoreProvider.overrideWithValue(store),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  testWidgets('valida o e-mail antes de enviar', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.tap(find.widgetWithText(FilledButton, 'Enviar código'));
    await tester.pump();

    expect(find.text('Informe o e-mail.'), findsOneWidget);
    verifyNever(() => authApi.forgotPassword(email: any(named: 'email')));
  });

  testWidgets('fluxo: envia código -> redefine -> volta pro login', (
    tester,
  ) async {
    when(
      () => authApi.forgotPassword(email: any(named: 'email')),
    ).thenAnswer((_) async {});
    when(
      () => authApi.resetPassword(
        code: any(named: 'code'),
        newPassword: any(named: 'newPassword'),
      ),
    ).thenAnswer((_) async {});

    await tester.pumpWidget(buildApp());

    await tester.enterText(find.byType(TextFormField), 'user@test.dev');
    await tester.tap(find.widgetWithText(FilledButton, 'Enviar código'));
    await tester.pumpAndSettle();

    // fase 2: campos de código + senha
    verify(() => authApi.forgotPassword(email: 'user@test.dev')).called(1);
    expect(find.text('Redefinir senha'), findsOneWidget);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'abcd 2345'); // vira ABCD2345
    await tester.enterText(fields.at(1), 'nova-senha-1');
    await tester.enterText(fields.at(2), 'nova-senha-1');
    await tester.tap(find.widgetWithText(FilledButton, 'Redefinir senha'));
    await tester.pumpAndSettle();

    verify(
      () => authApi.resetPassword(
        code: 'ABCD2345',
        newPassword: 'nova-senha-1',
      ),
    ).called(1);
    expect(find.text('Senha redefinida. Entre com a nova senha.'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Ir para o login'));
    await tester.pumpAndSettle();
    expect(find.text('LOGIN'), findsOneWidget);
  });

  testWidgets('erro da API no reset aparece na tela', (tester) async {
    when(
      () => authApi.forgotPassword(email: any(named: 'email')),
    ).thenAnswer((_) async {});
    when(
      () => authApi.resetPassword(
        code: any(named: 'code'),
        newPassword: any(named: 'newPassword'),
      ),
    ).thenThrow(
      const ApiException(
        code: 'INVALID_RESET_TOKEN',
        message: 'x',
        statusCode: 400,
      ),
    );

    await tester.pumpWidget(buildApp());
    await tester.enterText(find.byType(TextFormField), 'user@test.dev');
    await tester.tap(find.widgetWithText(FilledButton, 'Enviar código'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'WRONGCOD');
    await tester.enterText(fields.at(1), 'nova-senha-1');
    await tester.enterText(fields.at(2), 'nova-senha-1');
    await tester.tap(find.widgetWithText(FilledButton, 'Redefinir senha'));
    await tester.pumpAndSettle();

    expect(
      find.text('Código de recuperação inválido ou expirado.'),
      findsOneWidget,
    );
  });
}
