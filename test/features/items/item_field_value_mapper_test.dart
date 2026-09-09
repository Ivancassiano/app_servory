import 'package:flutter_test/flutter_test.dart';
import 'package:servory/features/items/data/item_field_value_mapper.dart';

void main() {
  Map<String, dynamic> json(Object? valueNumber) => {
    'id': 'v1',
    'item_id': 'i1',
    'field_def_id': 'd1',
    'value_text': null,
    'value_number': valueNumber,
    'value_datetime': null,
    'value_boolean': null,
    'version': 1,
    'created_at': '2026-09-09T12:00:00Z',
    'updated_at': '2026-09-09T12:00:00Z',
  };

  test('value_number vem como string do backend (pgtype.Numeric)', () {
    // O backend serializa NUMERIC como string p/ não perder precisão.
    expect(itemFieldValueFromApiJson(json('2.0'), organizationId: 'o1').valueNumber, 2.0);
    expect(itemFieldValueFromApiJson(json('1'), organizationId: 'o1').valueNumber, 1.0);
    expect(itemFieldValueFromApiJson(json('2.5'), organizationId: 'o1').valueNumber, 2.5);
  });

  test('tolera número cru e nulo', () {
    expect(itemFieldValueFromApiJson(json(3), organizationId: 'o1').valueNumber, 3.0);
    expect(itemFieldValueFromApiJson(json(null), organizationId: 'o1').valueNumber, isNull);
  });
}
