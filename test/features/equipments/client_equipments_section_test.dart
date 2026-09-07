import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servory/core/db/app_database.dart';
import 'package:servory/features/equipments/application/equipments_provider.dart';
import 'package:servory/features/equipments/data/equipment_mapper.dart';
import 'package:servory/features/equipments/presentation/client_equipments_section.dart';
import 'package:servory/features/locations/application/locations_provider.dart';
import 'package:servory/features/locations/data/location_mapper.dart';

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
  final locations = [
    _loc('l1', 'c1', 'Matriz'),
    _loc('l2', 'c1', 'Filial'),
    _loc('l3', 'c2', 'Outro cliente'),
  ];

  Widget host(List<LocalEquipment> equipments) => ProviderScope(
    overrides: [
      equipmentListProvider.overrideWith((ref) => Stream.value(equipments)),
      locationListProvider.overrideWith((ref) => Stream.value(locations)),
    ],
    child: const MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ClientEquipmentsSection(clientId: 'c1'),
        ),
      ),
    ),
  );

  testWidgets('lista equipamentos do cliente através de vários locais', (
    tester,
  ) async {
    await tester.pumpWidget(
      host([
        _eq('e1', 'l1', 'Forno'),
        _eq('e2', 'l2', 'Geladeira'),
        _eq('e3', 'l3', 'De outro cliente'),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Equipamentos (2)'), findsOneWidget);
    expect(find.text('Forno'), findsOneWidget);
    expect(find.text('Geladeira'), findsOneWidget);
    expect(find.text('De outro cliente'), findsNothing);
  });

  testWidgets('"Ver todos" aparece só com mais de 4', (tester) async {
    await tester.pumpWidget(
      host([for (var i = 0; i < 6; i++) _eq('e$i', 'l1', 'Equip $i')]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ver todos (6)'), findsOneWidget);
    expect(find.text('Equip 0'), findsOneWidget);
    expect(find.text('Equip 4'), findsNothing); // prévia de 4
  });
}
