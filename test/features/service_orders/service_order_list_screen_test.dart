import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servory/features/service_orders/application/service_orders_provider.dart';
import 'package:servory/features/service_orders/data/service_order_mapper.dart';
import 'package:servory/features/service_orders/presentation/service_order_list_screen.dart';

ServiceOrderWithClient _order(String id, String status, String client) {
  final o = serviceOrderFromApiJson({
    'id': id,
    'client_id': 'c-$id',
    'status': status,
    'reason': 'motivo $id',
  }, organizationId: 'org');
  return ServiceOrderWithClient(order: o, clientName: client);
}

void main() {
  final orders = [
    _order('1', 'draft', 'Padaria Central'),
    _order('2', 'open', 'Bar do Zé'),
    _order('3', 'completed', 'Loja Norte'),
  ];

  Widget host() => ProviderScope(
    overrides: [
      serviceOrderListProvider.overrideWithValue(AsyncValue.data(orders)),
    ],
    child: const MaterialApp(home: ServiceOrderListScreen()),
  );

  testWidgets('lista todas e filtra pelo chip de status', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    expect(find.text('Padaria Central'), findsOneWidget);
    expect(find.text('Bar do Zé'), findsOneWidget);
    expect(find.text('Loja Norte'), findsOneWidget);

    await tester.tap(find.text('Aberta'));
    await tester.pumpAndSettle();

    expect(find.text('Bar do Zé'), findsOneWidget);
    expect(find.text('Padaria Central'), findsNothing);
    expect(find.text('Loja Norte'), findsNothing);
  });

  testWidgets('busca por nome do cliente', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'loja');
    await tester.pumpAndSettle();

    expect(find.text('Loja Norte'), findsOneWidget);
    expect(find.text('Padaria Central'), findsNothing);
    expect(find.text('Bar do Zé'), findsNothing);
  });
}
