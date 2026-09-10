import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:servory/features/service_orders/application/service_orders_provider.dart';
import 'package:servory/features/service_orders/data/service_order_mapper.dart';
import 'package:servory/features/service_orders/presentation/related_service_orders_section.dart';

ServiceOrderWithClient _order(
  String id, {
  String? itemId,
  String status = 'open',
  String? createdAt,
}) {
  final o = serviceOrderFromApiJson({
    'id': id,
    'client_id': 'c1',
    'item_id': itemId,
    'status': status,
    'reason': 'motivo $id',
    'created_at': createdAt,
  }, organizationId: 'org');
  return ServiceOrderWithClient(order: o, clientName: 'Cliente');
}

void main() {
  GoRouter buildRouter() => GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(
          body: SingleChildScrollView(
            child: RelatedServiceOrdersSection(itemId: 'eq-1'),
          ),
        ),
      ),
      GoRoute(
        path: '/service-orders',
        builder: (_, state) =>
            Scaffold(body: Text('lista ${state.uri.query}')),
      ),
    ],
  );

  Widget host(List<ServiceOrderWithClient> orders) => ProviderScope(
    overrides: [
      serviceOrderListProvider.overrideWithValue(AsyncValue.data(orders)),
    ],
    child: MaterialApp.router(routerConfig: buildRouter()),
  );

  testWidgets('lista só os laudos do escopo e leva pra lista filtrada', (
    tester,
  ) async {
    await tester.pumpWidget(
      host([
        _order(
          '1',
          itemId: 'eq-1',
          status: 'completed',
          createdAt: '2026-01-10T09:05:00Z',
        ),
        _order('2', itemId: 'eq-1', createdAt: '2026-03-22T14:30:00Z'),
        _order('3', itemId: 'outro', createdAt: '2026-05-01T08:00:00Z'),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Laudos (2)'), findsOneWidget);
    expect(find.textContaining('Concluída · motivo 1'), findsOneWidget);
    expect(find.textContaining('Aberta · motivo 2'), findsOneWidget);
    expect(find.textContaining('motivo 3'), findsNothing);

    // data/hora de cadastro visível (local); ordem: mais recente primeiro
    final titles = tester
        .widgetList<Text>(
          find.descendant(
            of: find.byType(ListTile),
            matching: find.byType(Text),
          ),
        )
        .map((t) => t.data)
        .toList();
    expect(titles.any((t) => t!.startsWith('22/03/2026')), isTrue);
    expect(titles.any((t) => t!.startsWith('10/01/2026')), isTrue);
    expect(
      titles.indexWhere((t) => t!.startsWith('22/03/2026')),
      lessThan(titles.indexWhere((t) => t!.startsWith('10/01/2026'))),
    );

    await tester.tap(find.text('Ver todos (2)'));
    await tester.pumpAndSettle();
    expect(find.text('lista itemId=eq-1'), findsOneWidget);
  });

  testWidgets('sem laudos mostra o vazio', (tester) async {
    await tester.pumpWidget(host([_order('9', itemId: 'outro')]));
    await tester.pumpAndSettle();

    expect(find.text('Laudos (0)'), findsOneWidget);
    expect(find.text('Nenhum laudo relacionado.'), findsOneWidget);
    expect(find.text('Ver todos (0)'), findsNothing);
  });
}
