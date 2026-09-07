import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servory/core/db/app_database.dart';
import 'package:servory/features/clients/application/clients_provider.dart';
import 'package:servory/features/clients/data/client_mapper.dart';
import 'package:servory/features/equipments/data/equipment_type_repository.dart';
import 'package:servory/features/equipments/presentation/equipment_detail_screen.dart';
import 'package:servory/features/locations/application/locations_provider.dart';
import 'package:servory/features/locations/data/location_mapper.dart';

class _FakeTypeRepo implements EquipmentTypeRepository {
  @override
  Stream<List<LocalEquipmentType>> watchList() =>
      Stream.value(const <LocalEquipmentType>[]);
  @override
  Future<void> refresh() async {}
}

LocalClient _client(String id, String name) =>
    clientFromApiJson({'id': id, 'name': name}, organizationId: 'org');

LocalLocation _loc(String id, String clientId, String name) =>
    locationFromApiJson({
      'id': id,
      'client_id': clientId,
      'name': name,
    }, organizationId: 'org');

void main() {
  final clients = [_client('c1', 'Padaria Central'), _client('c2', 'Bar do Zé')];
  final locations = [
    _loc('l1', 'c1', 'Matriz'),
    _loc('l2', 'c1', 'Filial Sul'),
    _loc('l3', 'c2', 'Depósito'),
  ];

  Widget host({String? presetClientId}) => ProviderScope(
    overrides: [
      clientListProvider.overrideWith((ref) => Stream.value(clients)),
      locationListProvider.overrideWith((ref) => Stream.value(locations)),
      equipmentTypeRepositoryProvider.overrideWithValue(_FakeTypeRepo()),
    ],
    child: MaterialApp(
      home: EquipmentDetailScreen(
        equipmentId: 'new',
        presetClientId: presetClientId,
      ),
    ),
  );

  testWidgets('escolher o cliente filtra o dropdown de local', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Abre o dropdown de Cliente e escolhe "Padaria Central".
    await tester.tap(find.text('Cliente'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Padaria Central').last);
    await tester.pumpAndSettle();

    // Agora o dropdown de Local só oferece os locais da Padaria.
    await tester.tap(find.text('Local'));
    await tester.pumpAndSettle();
    expect(find.text('Matriz'), findsOneWidget);
    expect(find.text('Filial Sul'), findsOneWidget);
    expect(find.text('Depósito'), findsNothing);
  });

  testWidgets('presetClientId trava o cliente', (tester) async {
    await tester.pumpWidget(host(presetClientId: 'c2'));
    await tester.pumpAndSettle();

    expect(find.text('Bar do Zé'), findsOneWidget);
    // Sem dropdown de cliente (é um campo travado).
    expect(find.text('Cliente'), findsOneWidget);

    await tester.tap(find.text('Local'));
    await tester.pumpAndSettle();
    expect(find.text('Depósito'), findsOneWidget);
    expect(find.text('Matriz'), findsNothing);
  });
}
