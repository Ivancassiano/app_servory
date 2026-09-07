import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:servory/features/service_orders/application/service_orders_provider.dart';
import 'package:servory/features/service_orders/data/service_order_mapper.dart';
import 'package:servory/features/service_orders/presentation/related_service_orders_section.dart';

ServiceOrderWithClient _order(
  String id, {
  String? locationId,
  String? equipmentId,
  String status = 'open',
}) {
  final o = serviceOrderFromApiJson({
    'id': id,
    'client_id': 'c1',
    'location_id': locationId,
    'equipment_id': equipmentId,
    'status': status,
    'reason': 'motivo $id',
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
            child: RelatedServiceOrdersSection(equipmentId: 'eq-1'),
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
        _order('1', equipmentId: 'eq-1', status: 'completed'),
        _order('2', equipmentId: 'eq-1'),
        _order('3', equipmentId: 'outro'),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Laudos (2)'), findsOneWidget);
    expect(find.text('motivo 1'), findsOneWidget);
    expect(find.text('motivo 2'), findsOneWidget);
    expect(find.text('motivo 3'), findsNothing);

    await tester.tap(find.text('Ver todos (2)'));
    await tester.pumpAndSettle();
    expect(find.text('lista equipmentId=eq-1'), findsOneWidget);
  });

  testWidgets('sem laudos mostra o vazio', (tester) async {
    await tester.pumpWidget(host([_order('9', equipmentId: 'outro')]));
    await tester.pumpAndSettle();

    expect(find.text('Laudos (0)'), findsOneWidget);
    expect(find.text('Nenhum laudo relacionado.'), findsOneWidget);
    expect(find.text('Ver todos (0)'), findsNothing);
  });
}
