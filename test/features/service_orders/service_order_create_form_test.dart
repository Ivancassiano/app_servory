import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servory/core/db/app_database.dart';
import 'package:servory/features/clients/application/clients_provider.dart';
import 'package:servory/features/clients/data/client_mapper.dart';
import 'package:servory/features/equipments/application/equipments_provider.dart';
import 'package:servory/features/locations/application/locations_provider.dart';
import 'package:servory/features/reference/data/reference_repository.dart';
import 'package:servory/features/service_orders/presentation/service_order_detail_screen.dart';

LocalClient _client(String id, String name) =>
    clientFromApiJson({'id': id, 'name': name}, organizationId: 'org');

class _FakeReferenceRepo implements ReferenceDataRepository {
  @override
  Stream<List<ReferenceItem>> watchList(ReferenceKind kind) =>
      Stream.value(const <ReferenceItem>[]);
  @override
  Future<void> refresh(ReferenceKind kind) async {}
}

void main() {
  Widget host() => ProviderScope(
    overrides: [
      referenceDataRepositoryProvider.overrideWithValue(_FakeReferenceRepo()),
      clientListProvider.overrideWith(
        (ref) => Stream.value([_client('c1', 'Padaria Central')]),
      ),
      locationListProvider.overrideWith(
        (ref) => Stream.value(const <LocalLocation>[]),
      ),
      equipmentListProvider.overrideWith(
        (ref) => Stream.value(const <LocalEquipment>[]),
      ),
      for (final k in ReferenceKind.values)
        referenceListProvider(k).overrideWith(
          (ref) => Stream.value(const <ReferenceItem>[]),
        ),
    ],
    child: const MaterialApp(home: ServiceOrderDetailScreen(serviceOrderId: 'new')),
  );

  testWidgets('criação: sem switch "Abrir imediatamente"; botões Iniciar + Rascunho', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    expect(find.text('Abrir imediatamente'), findsNothing);
    expect(find.byType(SwitchListTile), findsNothing);

    // sem data agendada → botão principal é "Iniciar ordem"
    expect(find.widgetWithText(FilledButton, 'Iniciar ordem'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Agendar ordem'), findsNothing);
    expect(find.widgetWithText(TextButton, 'Salvar rascunho'), findsOneWidget);
  });
}
