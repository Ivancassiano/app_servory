import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servory/core/db/app_database.dart';
import 'package:servory/features/locations/application/locations_provider.dart';
import 'package:servory/features/locations/data/location_mapper.dart';
import 'package:servory/features/locations/presentation/client_locations_section.dart';

LocalLocation _loc(
  String id,
  String clientId,
  String name, {
  String city = '',
}) => locationFromApiJson({
  'id': id,
  'client_id': clientId,
  'name': name,
  'city': city,
}, organizationId: 'org');

void main() {
  testWidgets('lista só os locais do cliente e conta', (tester) async {
    final locations = [
      _loc('l1', 'c1', 'Matriz', city: 'Recife'),
      _loc('l2', 'c1', 'Filial Sul'),
      _loc('l3', 'c2', 'Outra empresa'),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          locationListProvider.overrideWith((ref) => Stream.value(locations)),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ClientLocationsSection(clientId: 'c1'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Locais (2)'), findsOneWidget);
    expect(find.text('Matriz'), findsOneWidget);
    expect(find.text('Filial Sul'), findsOneWidget);
    expect(find.text('Outra empresa'), findsNothing);
    expect(find.widgetWithText(OutlinedButton, 'Novo local'), findsOneWidget);
  });

  testWidgets('sem locais mostra a mensagem vazia', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          locationListProvider.overrideWith(
            (ref) => Stream.value(<LocalLocation>[]),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: ClientLocationsSection(clientId: 'c1')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nenhum local para este cliente.'), findsOneWidget);
  });
}
