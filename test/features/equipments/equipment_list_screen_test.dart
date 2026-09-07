import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servory/core/db/app_database.dart';
import 'package:servory/features/clients/application/clients_provider.dart';
import 'package:servory/features/clients/data/client_mapper.dart';
import 'package:servory/features/equipments/application/equipments_provider.dart';
import 'package:servory/features/equipments/data/equipment_mapper.dart';
import 'package:servory/features/equipments/presentation/equipment_list_screen.dart';
import 'package:servory/features/locations/application/locations_provider.dart';
import 'package:servory/features/locations/data/location_mapper.dart';

LocalClient _client(String id, String name) =>
    clientFromApiJson({'id': id, 'name': name}, organizationId: 'org');

LocalLocation _loc(String id, String clientId, String name) =>
    locationFromApiJson({
      'id': id,
      'client_id': clientId,
      'name': name,
    }, organizationId: 'org');

LocalEquipment _eq(String id, String locationId, String name) =>
    equipmentFromApiJson({
      'id': id,
      'location_id': locationId,
      'equipment_type_id': 't1',
      'name': name,
    }, organizationId: 'org');

void main() {
  final clients = [_client('c1', 'Padaria Central'), _client('c2', 'Bar do Zé')];
  final locations = [
    _loc('l1', 'c1', 'Matriz'),
    _loc('l2', 'c2', 'Depósito'),
  ];
  final equipments = [
    _eq('e1', 'l1', 'Forno'),
    _eq('e2', 'l2', 'Chopeira'),
  ];

  Widget host({String? clientId}) => ProviderScope(
    overrides: [
      equipmentListProvider.overrideWith((ref) => Stream.value(equipments)),
      locationListProvider.overrideWith((ref) => Stream.value(locations)),
      clientListProvider.overrideWith((ref) => Stream.value(clients)),
      equipmentListPagingProvider.overrideWithValue(null),
    ],
    child: MaterialApp(home: EquipmentListScreen(clientId: clientId)),
  );

  testWidgets('mostra cliente · local no subtítulo', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    expect(find.text('Forno'), findsOneWidget);
    expect(find.text('Padaria Central · Matriz'), findsOneWidget);
    expect(find.text('Bar do Zé · Depósito'), findsOneWidget);
  });

  testWidgets('busca pelo cliente e pelo local', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'depósito');
    await tester.pumpAndSettle();
    expect(find.text('Chopeira'), findsOneWidget);
    expect(find.text('Forno'), findsNothing);

    await tester.enterText(find.byType(TextField), 'padaria');
    await tester.pumpAndSettle();
    expect(find.text('Forno'), findsOneWidget);
    expect(find.text('Chopeira'), findsNothing);
  });

  testWidgets('clientId filtra pelos locais do cliente', (tester) async {
    await tester.pumpWidget(host(clientId: 'c1'));
    await tester.pumpAndSettle();

    expect(find.text('Forno'), findsOneWidget);
    expect(find.text('Chopeira'), findsNothing);
    expect(find.text('Cliente: Padaria Central'), findsOneWidget);
  });
}
