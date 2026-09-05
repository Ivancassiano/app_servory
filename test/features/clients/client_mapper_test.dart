import 'package:flutter_test/flutter_test.dart';
import 'package:servory/features/clients/data/client_mapper.dart';

void main() {
  test('clientFromApiJson mapeia o shape REST/sync', () {
    final c = clientFromApiJson(const {
      'id': 'c1',
      'kind': 'legal',
      'name': 'ClimaTech',
      'legal_name': 'ClimaTech LTDA',
      'tax_id': '12.345.678/0001-90',
      'phone': '11999',
      'email': 'a@b.c',
      'contact_person': 'Ana',
      // internal_notes ausente = sem permissão de leitura
      'version': 3,
      'created_at': '2026-01-02T03:04:05Z',
      'updated_at': '2026-02-02T03:04:05Z',
    }, organizationId: 'org1');

    expect(c.id, 'c1');
    expect(c.organizationId, 'org1');
    expect(c.name, 'ClimaTech');
    expect(c.legalName, 'ClimaTech LTDA');
    expect(c.internalNotes, isNull);
    expect(c.version, 3);
    expect(c.syncStatus, 'synced');
    expect(c.deleted, isFalse);
    expect(c.createdAt, DateTime.utc(2026, 1, 2, 3, 4, 5));
  });

  test('defaults quando o servidor omite campos', () {
    final c = clientFromApiJson(
      const {'id': 'c2', 'name': 'X'},
      organizationId: 'org1',
    );
    expect(c.kind, 'legal');
    expect(c.phone, '');
    expect(c.version, isNull);
  });

  test('bodies emitem só os campos aceitos', () {
    expect(
      clientCreateBody(kind: 'individual', name: 'Y', phone: '9'),
      {'kind': 'individual', 'name': 'Y', 'phone': '9'},
    );
    expect(clientUpdateBody(name: 'Z', phone: ''), {'name': 'Z', 'phone': ''});
  });
}
