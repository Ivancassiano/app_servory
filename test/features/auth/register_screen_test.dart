import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:servory/core/network/api_exception.dart';
import 'package:servory/core/providers.dart';
import 'package:servory/core/storage/secure_store.dart';
import 'package:servory/features/auth/data/auth_api.dart';
import 'package:servory/features/auth/presentation/register_screen.dart';

class MockAuthApi extends Mock implements AuthApi {}

class MockSecureStore extends Mock implements SecureStore {}

void main() {
  late MockAuthApi authApi;
  late MockSecureStore store;

  setUp(() {
    authApi = MockAuthApi();
    store = MockSecureStore();
    when(() => store.readAccessToken()).thenAnswer((_) async => null);
    when(() => store.readRefreshToken()).thenAnswer((_) async => null);
    when(() => store.readOrganizationId()).thenAnswer((_) async => null);
    when(() => store.readUserId()).thenAnswer((_) async => null);
  });

  Widget buildApp() {
    final router = GoRouter(
      initialLocation: '/register',
      routes: [
        GoRoute(
          path: '/register',
          builder: (_, _) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/verify-email',
          builder: (_, state) => Scaffold(
            body: Text('verify ${state.uri.queryParameters['email']}'),
          ),
        ),
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

  testWidgets('valida campos obrigatórios antes de chamar o cadastro', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());

    await tester.ensureVisible(
      find.widgetWithText(FilledButton, 'Criar conta'),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Criar conta'));
    await tester.pump();

    expect(find.text('Informe o nome da organização.'), findsOneWidget);
    expect(find.text('Informe seu nome.'), findsOneWidget);
    verifyNever(
      () => authApi.register(
        organizationName: any(named: 'organizationName'),
        name: any(named: 'name'),
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    );
  });

  testWidgets('senhas diferentes bloqueiam o envio', (tester) async {
    await tester.pumpWidget(buildApp());

    await tester.enterText(find.byType(TextFormField).at(0), 'Minha Org');
    await tester.enterText(find.byType(TextFormField).at(1), 'Fulano');
    await tester.enterText(find.byType(TextFormField).at(2), 'a@b.com');
    await tester.enterText(find.byType(TextFormField).at(3), 'Senha-1234');
    await tester.enterText(find.byType(TextFormField).at(4), 'Outra-5678');
    await tester.ensureVisible(
      find.widgetWithText(FilledButton, 'Criar conta'),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Criar conta'));
    await tester.pump();

    expect(find.text('As senhas não conferem.'), findsOneWidget);
  });

  testWidgets('cadastro válido chama a API e vai pra confirmação de e-mail', (
    tester,
  ) async {
    when(
      () => authApi.register(
        organizationName: any(named: 'organizationName'),
        name: any(named: 'name'),
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async {});

    await tester.pumpWidget(buildApp());

    await tester.enterText(find.byType(TextFormField).at(0), 'Minha Org');
    await tester.enterText(find.byType(TextFormField).at(1), 'Fulano');
    await tester.enterText(find.byType(TextFormField).at(2), 'novo@b.com');
    await tester.enterText(find.byType(TextFormField).at(3), 'Senha-1234');
    await tester.enterText(find.byType(TextFormField).at(4), 'Senha-1234');
    await tester.ensureVisible(
      find.widgetWithText(FilledButton, 'Criar conta'),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Criar conta'));
    await tester.pumpAndSettle();

    verify(
      () => authApi.register(
        organizationName: 'Minha Org',
        name: 'Fulano',
        email: 'novo@b.com',
        password: 'Senha-1234',
      ),
    ).called(1);
    expect(find.text('verify novo@b.com'), findsOneWidget);
  });

  testWidgets('erro da API aparece na tela', (tester) async {
    when(
      () => authApi.register(
        organizationName: any(named: 'organizationName'),
        name: any(named: 'name'),
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(
      const ApiException(
        code: 'EMAIL_EXISTS',
        message: 'dup',
        statusCode: 409,
      ),
    );

    await tester.pumpWidget(buildApp());

    await tester.enterText(find.byType(TextFormField).at(0), 'Minha Org');
    await tester.enterText(find.byType(TextFormField).at(1), 'Fulano');
    await tester.enterText(find.byType(TextFormField).at(2), 'dup@b.com');
    await tester.enterText(find.byType(TextFormField).at(3), 'Senha-1234');
    await tester.enterText(find.byType(TextFormField).at(4), 'Senha-1234');
    await tester.ensureVisible(
      find.widgetWithText(FilledButton, 'Criar conta'),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Criar conta'));
    await tester.pumpAndSettle();

    expect(find.text('Já existe uma conta com esse e-mail.'), findsOneWidget);
  });
}
