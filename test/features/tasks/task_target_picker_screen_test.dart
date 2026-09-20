import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servory/features/clients/application/clients_provider.dart';
import 'package:servory/features/clients/data/client_mapper.dart';
import 'package:servory/features/items/application/items_provider.dart';
import 'package:servory/features/items/data/item_mapper.dart';
import 'package:servory/features/locations/application/locations_provider.dart';
import 'package:servory/features/locations/data/location_mapper.dart';
import 'package:servory/features/tasks/data/task_mapper.dart';
import 'package:servory/features/tasks/presentation/task_target_picker_screen.dart';

// Árvore de teste:
//   Cliente A
//     Local A1
//       Item A1-1
//     Item A-solto (direto no cliente, sem local)
//   Local 3 (sem cliente)
//   Item 4 (sem cliente nem local)
//   Local 5 (sem cliente)
//     Item 5
final _clients = [
  clientFromApiJson({'id': 'clA', 'name': 'Cliente A'}, organizationId: 'org'),
];
final _locations = [
  locationFromApiJson(
    {'id': 'locA1', 'client_id': 'clA', 'name': 'Local A1'},
    organizationId: 'org',
  ),
  locationFromApiJson({'id': 'loc3', 'name': 'Local 3'}, organizationId: 'org'),
  locationFromApiJson({'id': 'loc5', 'name': 'Local 5'}, organizationId: 'org'),
];
final _items = [
  itemFromApiJson({
    'id': 'itA11',
    'client_id': 'clA',
    'location_id': 'locA1',
    'name': 'Item A1-1',
  }, organizationId: 'org'),
  itemFromApiJson({
    'id': 'itASolto',
    'client_id': 'clA',
    'name': 'Item A-solto',
  }, organizationId: 'org'),
  itemFromApiJson({'id': 'it4', 'name': 'Item 4'}, organizationId: 'org'),
  itemFromApiJson({
    'id': 'it5',
    'location_id': 'loc5',
    'name': 'Item 5',
  }, organizationId: 'org'),
];

Widget _host({
  String? clientId,
  List<TaskTargetInput> initial = const [],
  required ValueChanged<List<TaskTargetInput>?> onResult,
}) => ProviderScope(
  overrides: [
    clientListProvider.overrideWith((ref) => Stream.value(_clients)),
    locationListProvider.overrideWith((ref) => Stream.value(_locations)),
    itemListProvider.overrideWith((ref) => Stream.value(_items)),
  ],
  child: MaterialApp(
    home: Builder(
      builder: (context) => ElevatedButton(
        onPressed: () async {
          final result = await Navigator.of(context)
              .push<List<TaskTargetInput>>(
                MaterialPageRoute(
                  builder: (_) => TaskTargetPickerScreen(
                    clientId: clientId,
                    initialTargets: initial,
                  ),
                ),
              );
          onResult(result);
        },
        child: const Text('abrir'),
      ),
    ),
  ),
);

void main() {
  testWidgets('mostra a árvore inteira sem cliente informado', (tester) async {
    await tester.pumpWidget(_host(onResult: (_) {}));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Cliente A'), findsOneWidget);
    expect(find.text('Local A1'), findsOneWidget);
    expect(find.text('Item A1-1'), findsOneWidget);
    expect(find.text('Item A-solto'), findsOneWidget);
    expect(find.text('Local 3'), findsOneWidget);
    expect(find.text('Item 4'), findsOneWidget);
    expect(find.text('Local 5'), findsOneWidget);
    expect(find.text('Item 5'), findsOneWidget);
  });

  testWidgets(
    'com clientId, só mostra o que é do cliente (sem nó de cliente)',
    (tester) async {
      await tester.pumpWidget(_host(clientId: 'clA', onResult: (_) {}));
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      expect(find.text('Cliente A'), findsNothing);
      expect(find.text('Local A1'), findsOneWidget);
      expect(find.text('Item A1-1'), findsOneWidget);
      expect(find.text('Item A-solto'), findsOneWidget);
      expect(find.text('Local 3'), findsNothing);
      expect(find.text('Item 4'), findsNothing);
    },
  );

  testWidgets(
    'marcar um local marca os itens dele; o local em si também vira alvo',
    (tester) async {
      List<TaskTargetInput>? result;
      await tester.pumpWidget(_host(onResult: (r) => result = r));
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(InkWell, 'Local 5'));
      await tester.pumpAndSettle();

      expect(find.text('Selecionar (2)'), findsOneWidget);
      await tester.tap(find.text('Selecionar (2)'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.length, 2);
      expect(
        result!.any((t) => t.locationId == 'loc5' && t.itemId == null),
        isTrue,
        reason: 'local em si deve virar um alvo',
      );
      expect(
        result!.any((t) => t.locationId == 'loc5' && t.itemId == 'it5'),
        isTrue,
        reason: 'item do local deve ser auto-selecionado',
      );
    },
  );

  testWidgets(
    'desmarcar um item auto-selecionado tira só ele, mantém o local',
    (tester) async {
      List<TaskTargetInput>? result;
      await tester.pumpWidget(_host(onResult: (r) => result = r));
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(InkWell, 'Local 5'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(InkWell, 'Item 5'));
      await tester.pumpAndSettle();

      expect(find.text('Selecionar (1)'), findsOneWidget);
      await tester.tap(find.text('Selecionar (1)'));
      await tester.pumpAndSettle();

      expect(result!.map((t) => t.toJson()), [
        {'location_id': 'loc5', 'item_id': null},
      ]);
    },
  );

  testWidgets(
    'marcar um item direto do cliente não seleciona outros irmãos',
    (tester) async {
      List<TaskTargetInput>? result;
      await tester.pumpWidget(_host(onResult: (r) => result = r));
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(InkWell, 'Item A-solto'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Selecionar (1)'));
      await tester.pumpAndSettle();

      expect(result!.map((t) => t.toJson()), [
        {'location_id': null, 'item_id': 'itASolto'},
      ]);
    },
  );

  testWidgets('marcar o cliente marca tudo dele em cascata', (tester) async {
    List<TaskTargetInput>? result;
    await tester.pumpWidget(_host(onResult: (r) => result = r));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(InkWell, 'Cliente A'));
    await tester.pumpAndSettle();

    expect(find.text('Selecionar (3)'), findsOneWidget);
    await tester.tap(find.text('Selecionar (3)'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.length, 3);
    expect(
      result!.any((t) => t.locationId == 'locA1' && t.itemId == null),
      isTrue,
    );
    expect(
      result!.any((t) => t.locationId == 'locA1' && t.itemId == 'itA11'),
      isTrue,
    );
    expect(
      result!.any((t) => t.locationId == null && t.itemId == 'itASolto'),
      isTrue,
    );
  });

  testWidgets('busca filtra a árvore mantendo os ancestrais', (tester) async {
    await tester.pumpWidget(_host(onResult: (_) {}));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'A1-1');
    await tester.pumpAndSettle();

    expect(find.text('Cliente A'), findsOneWidget);
    expect(find.text('Local A1'), findsOneWidget);
    expect(find.text('Item A1-1'), findsOneWidget);
    expect(find.text('Item A-solto'), findsNothing);
    expect(find.text('Local 3'), findsNothing);
  });

  testWidgets('volta sem selecionar nada devolve null (não mexe nos alvos)', (
    tester,
  ) async {
    List<TaskTargetInput>? result = const [
      TaskTargetInput(locationId: 'sentinel'),
    ];
    await tester.pumpWidget(_host(onResult: (r) => result = r));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(result, isNull);
  });
}
