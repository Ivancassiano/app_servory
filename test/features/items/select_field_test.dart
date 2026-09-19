import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servory/core/db/app_database.dart';
import 'package:servory/features/items/application/items_provider.dart';
import 'package:servory/features/items/presentation/item_custom_fields_form.dart';

final _now = DateTime(2026, 9, 20);

LocalItemFieldDef _def({bool required = false}) => LocalItemFieldDef(
  id: 'd1',
  organizationId: 'org',
  label: 'Cor',
  fieldKey: 'cor',
  dataType: 'select',
  required: required,
  position: 0,
  cachedAt: _now,
);

LocalItemFieldOption _opt(String value, String label, {bool active = true}) =>
    LocalItemFieldOption(
      id: 'id-$value',
      organizationId: 'org',
      fieldDefId: 'd1',
      label: label,
      value: value,
      position: 0,
      isActive: active,
      cachedAt: _now,
    );

void main() {
  // `code-azul` (ativa) e `code-verde` (inativada): o valor gravado no item é
  // sempre o código, nunca o rótulo.
  final options = [
    _opt('code-azul', 'Azul'),
    _opt('code-verde', 'Verde', active: false),
  ];

  Widget host({
    required String? current,
    required ValueChanged<Map<String, TypedFieldValue>> onChanged,
    bool required = false,
  }) => ProviderScope(
    overrides: [
      itemFieldDefsForTypeProvider(
        null,
      ).overrideWith((ref) => [_def(required: required)]),
      itemFieldOptionsProvider(
        'd1',
      ).overrideWith((ref) => Stream.value(options)),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ItemCustomFieldsForm(
            itemTypeId: null,
            initial: {
              if (current != null) 'd1': TypedFieldValue(text: current),
            },
            onChanged: onChanged,
          ),
        ),
      ),
    ),
  );

  testWidgets('valor numa opção inativa: mostra o rótulo e avisa', (
    tester,
  ) async {
    await tester.pumpWidget(host(current: 'code-verde', onChanged: (_) {}));
    await tester.pumpAndSettle();
    expect(find.text('Verde'), findsOneWidget);
    expect(find.text('code-verde'), findsNothing);
    expect(find.textContaining('Opção inativa'), findsOneWidget);
  });

  testWidgets('a seleção só oferece opções ativas', (tester) async {
    await tester.pumpWidget(host(current: 'code-verde', onChanged: (_) {}));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Verde'));
    await tester.pumpAndSettle();
    // a inativa aparece só como valor atual do campo (atrás da folha), nunca
    // como escolha dentro dela
    expect(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Azul'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Verde'),
      ),
      findsNothing,
    );
  });

  testWidgets('sem escolher outra, o valor antigo não é alterado', (
    tester,
  ) async {
    Map<String, TypedFieldValue>? last;
    await tester.pumpWidget(
      host(current: 'code-verde', onChanged: (v) => last = v),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Verde'));
    await tester.pumpAndSettle();
    // fecha a folha sem escolher (toque fora)
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    expect(last, isNull); // nada foi emitido
    expect(find.text('Verde'), findsOneWidget);
  });

  testWidgets('escolher outra opção emite o CÓDIGO da nova', (tester) async {
    Map<String, TypedFieldValue>? last;
    await tester.pumpWidget(
      host(current: 'code-verde', onChanged: (v) => last = v),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Verde'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Azul'),
      ),
    );
    await tester.pumpAndSettle();

    expect(last!['d1']!.text, 'code-azul');
    expect(find.text('Azul'), findsOneWidget);
    expect(find.textContaining('Opção inativa'), findsNothing);
  });

  testWidgets('campo opcional pode ser limpo', (tester) async {
    Map<String, TypedFieldValue>? last;
    await tester.pumpWidget(
      host(current: 'code-verde', onChanged: (v) => last = v),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Verde'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Limpar seleção'));
    await tester.pumpAndSettle();
    expect(last, isEmpty);
    expect(find.text('Selecionar…'), findsOneWidget);
  });

  testWidgets('campo obrigatório não oferece limpar', (tester) async {
    await tester.pumpWidget(
      host(current: 'code-verde', required: true, onChanged: (_) {}),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Verde'));
    await tester.pumpAndSettle();
    expect(find.text('Limpar seleção'), findsNothing);
  });
}
