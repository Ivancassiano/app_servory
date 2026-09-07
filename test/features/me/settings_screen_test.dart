import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:servory/features/me/application/me_provider.dart';
import 'package:servory/features/me/data/me_api.dart';
import 'package:servory/features/me/presentation/settings_screen.dart';

void main() {
  const identity = Identity(
    userId: 'u1',
    email: 'dev@servory.local',
    name: 'Dev',
    organizationId: 'o1',
    organizationName: 'Servory Dev',
    role: 'admin',
    permissionVersion: 1,
  );

  GoRouter router() => GoRouter(
    initialLocation: '/settings',
    routes: [
      GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
      GoRoute(
        path: '/companies',
        builder: (_, _) => const Scaffold(body: Text('rota empresas')),
      ),
      GoRoute(
        path: '/label-batches',
        builder: (_, _) => const Scaffold(body: Text('rota etiquetas')),
      ),
      GoRoute(
        path: '/type-catalog',
        builder: (_, state) => Scaffold(
          body: Text('catálogo ${state.uri.queryParameters['kind']}'),
        ),
      ),
    ],
  );

  Widget host() => ProviderScope(
    overrides: [identityProvider.overrideWith((ref) async => identity)],
    child: MaterialApp.router(routerConfig: router()),
  );

  testWidgets('mostra identidade, Empresas, Etiquetas e Sair', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    expect(find.text('Servory Dev'), findsOneWidget);
    expect(find.text('Empresas'), findsOneWidget);
    expect(find.text('Etiquetas'), findsOneWidget);
    expect(find.text('Sair'), findsOneWidget);
    expect(find.text('Tipos de ordem de serviço'), findsOneWidget);
    expect(find.text('Tipos de equipamento'), findsOneWidget);
  });

  testWidgets('Tipos de ordem de serviço abre o catálogo certo', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tipos de ordem de serviço'));
    await tester.pumpAndSettle();

    expect(find.text('catálogo service-order'), findsOneWidget);
  });

  testWidgets('Empresas navega para /companies', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Empresas'));
    await tester.pumpAndSettle();

    expect(find.text('rota empresas'), findsOneWidget);
  });
}
