import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servory/core/db/app_database.dart';
import 'package:servory/features/clients/application/clients_provider.dart';
import 'package:servory/features/clients/data/client_mapper.dart';
import 'package:servory/features/locations/application/locations_provider.dart';
import 'package:servory/features/locations/data/location_mapper.dart';
import 'package:servory/features/locations/presentation/location_list_screen.dart';

LocalClient _client(String id, String name) =>
    clientFromApiJson({'id': id, 'name': name}, organizationId: 'org');

LocalLocation _loc(String id, String clientId, String name, {String city = ''}) =>
    locationFromApiJson({
      'id': id,
      'client_id': clientId,
      'name': name,
      'city': city,
    }, organizationId: 'org');

void main() {
  final clients = [_client('c1', 'Padaria Central'), _client('c2', 'Bar do Zé')];
  final locations = [
    _loc('l1', 'c1', 'Matriz', city: 'Recife'),
    _loc('l2', 'c1', 'Filial Sul'),
    _loc('l3', 'c2', 'Depósito'),
  ];

  Widget host({String? clientId}) => ProviderScope(
    overrides: [
      locationListProvider.overrideWith((ref) => Stream.value(locations)),
      clientListProvider.overrideWith((ref) => Stream.value(clients)),
      locationListPagingProvider.overrideWithValue(null),
    ],
    child: MaterialApp(home: LocationListScreen(clientId: clientId)),
  );

  testWidgets('mostra o cliente no subtítulo do local', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    expect(find.text('Matriz'), findsOneWidget);
    expect(find.text('Padaria Central · Recife'), findsOneWidget);
    expect(find.text('Bar do Zé · Depósito'), findsNothing); // subtítulo é "cliente · cidade|contato"
  });

  testWidgets('busca pelo nome do cliente filtra os locais', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'bar do');
    await tester.pumpAndSettle();

    expect(find.text('Depósito'), findsOneWidget);
    expect(find.text('Matriz'), findsNothing);
    expect(find.text('Filial Sul'), findsNothing);
  });

  testWidgets('clientId limita a lista e mostra o chip', (tester) async {
    await tester.pumpWidget(host(clientId: 'c2'));
    await tester.pumpAndSettle();

    expect(find.text('Depósito'), findsOneWidget);
    expect(find.text('Matriz'), findsNothing);
    expect(find.text('Cliente: Bar do Zé'), findsOneWidget);
  });
}
