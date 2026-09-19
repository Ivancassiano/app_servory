import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servory/features/items/presentation/field_options_editor.dart';

void main() {
  group('collectFieldOptions', () {
    test('mantém id e ativo/inativo; ignora linha nova em branco', () {
      final r = collectFieldOptions([
        FieldOptionDraft(id: 'a', label: ' Azul '),
        FieldOptionDraft(id: 'v', label: 'Verde', active: false),
        FieldOptionDraft(label: 'Amarelo'),
        FieldOptionDraft(label: '   '),
      ]);
      expect(r.error, isNull);
      expect(r.options, [
        (id: 'a', label: 'Azul', active: true),
        (id: 'v', label: 'Verde', active: false),
        (id: null, label: 'Amarelo', active: true),
      ]);
    });

    test('opção já salva sem descrição é erro (é preciso inativá-la)', () {
      final r = collectFieldOptions([
        FieldOptionDraft(id: 'a', label: ''),
        FieldOptionDraft(label: 'Novo'),
      ]);
      expect(r.options, isNull);
      expect(r.error, contains('inative'));
    });

    test('exige ao menos uma opção ativa', () {
      final r = collectFieldOptions([
        FieldOptionDraft(id: 'a', label: 'Azul', active: false),
      ]);
      expect(r.options, isNull);
      expect(r.error, 'Informe ao menos uma opção ativa.');
    });
  });

  group('FieldOptionsEditor', () {
    Widget host(List<FieldOptionDraft> drafts) => MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(child: FieldOptionsEditor(drafts: drafts)),
      ),
    );

    testWidgets('inativar mantém a opção (e o id) e reativar desfaz', (
      tester,
    ) async {
      final drafts = [FieldOptionDraft(id: 'a', label: 'Azul')];
      await tester.pumpWidget(host(drafts));

      await tester.tap(find.byTooltip('Inativar'));
      await tester.pump();
      expect(drafts.single.active, isFalse);
      expect(drafts.single.id, 'a');
      expect(find.text('Inativa — não aparece na seleção'), findsOneWidget);

      await tester.tap(find.byTooltip('Reativar'));
      await tester.pump();
      expect(drafts.single.active, isTrue);
    });

    testWidgets('adicionar cria linha nova; remover só existe para não salva', (
      tester,
    ) async {
      final drafts = [FieldOptionDraft(id: 'a', label: 'Azul')];
      await tester.pumpWidget(host(drafts));
      expect(find.byTooltip('Remover'), findsNothing);

      await tester.tap(find.text('Adicionar opção'));
      await tester.pump();
      expect(drafts, hasLength(2));
      expect(drafts.last.id, isNull);

      await tester.enterText(find.byType(TextField).last, 'Verde');
      expect(drafts.last.controller.text, 'Verde');

      await tester.tap(find.byTooltip('Remover'));
      await tester.pump();
      expect(drafts, hasLength(1));
      expect(drafts.single.id, 'a');
    });
  });
}
