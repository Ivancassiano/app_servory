import 'package:flutter_test/flutter_test.dart';
import 'package:servory/features/items/data/item_field_def_mapper.dart';
import 'package:servory/features/items/data/item_field_def_repository.dart'
    show selectOptionLabel;

void main() {
  test(
    'opções: is_active vem do servidor; ausente = ativa (servidor antigo)',
    () {
      final opts = itemFieldOptionsFromApiJson({
        'id': 'd1',
        'options': [
          {'id': 'o1', 'label': 'Azul', 'value': 'code-1', 'position': 0},
          {
            'id': 'o2',
            'label': 'Verde',
            'value': 'code-2',
            'position': 1,
            'is_active': false,
          },
        ],
      }, organizationId: 'org');
      expect(opts.map((o) => (o.value, o.isActive)), [
        ('code-1', true),
        ('code-2', false),
      ]);
    },
  );

  test('selectOptionLabel: rótulo da opção (ativa ou não); vazio se a lista '
      'não carregou; valor cru se a opção não existe (dado antigo)', () {
    final opts = itemFieldOptionsFromApiJson({
      'id': 'd1',
      'options': [
        {'id': 'o1', 'label': 'Azul', 'value': 'code-1'},
        {'id': 'o2', 'label': 'Verde', 'value': 'code-2', 'is_active': false},
      ],
    }, organizationId: 'org');
    expect(selectOptionLabel(opts, 'code-1'), 'Azul');
    expect(selectOptionLabel(opts, 'code-2'), 'Verde');
    expect(selectOptionLabel(const [], 'code-1'), '');
    expect(selectOptionLabel(opts, 'Sim'), 'Sim');
  });
}
