import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:servory/features/me/data/person_api.dart';

import '../../support/stub_dio.dart';

void main() {
  test('Person.fromJson lê o shape e trata campos ausentes', () {
    final p = Person.fromJson(const {
      'full_name': 'Ana Técnica',
      'tax_id': '123.456.789-00',
      'professional_registration': 'CREA-SP 987654',
    });
    expect(p.fullName, 'Ana Técnica');
    expect(p.taxId, '123.456.789-00');
    expect(p.professionalRegistration, 'CREA-SP 987654');
    expect(p.phone, '');
    expect(p.notes, '');
  });

  test('getMyPerson faz GET /v1/me/person', () async {
    final stub = StubDio(
      (req) => (status: 200, body: {'full_name': 'Ana', 'phone': '9999'}),
    );
    final person = await PersonApi(stub.dio).getMyPerson();
    expect(stub.lastRequest.method, 'GET');
    expect(stub.lastRequest.path, '/v1/me/person');
    expect(person.fullName, 'Ana');
    expect(person.phone, '9999');
  });

  test('updateMyPerson faz PATCH com os cinco campos', () async {
    final stub = StubDio(
      (req) => (status: 200, body: {'full_name': 'Ana', 'tax_id': '111'}),
    );
    await PersonApi(stub.dio).updateMyPerson(
      fullName: 'Ana',
      taxId: '111',
      phone: '',
      professionalRegistration: 'CFT-123',
      notes: '',
    );
    final req = stub.lastRequest;
    expect(req.method, 'PATCH');
    expect(req.path, '/v1/me/person');
    final body = req.data as Map<String, dynamic>;
    expect(body.keys, containsAll(<String>[
      'full_name',
      'tax_id',
      'phone',
      'professional_registration',
      'notes',
    ]));
    expect(body['professional_registration'], 'CFT-123');
    // corpo serializável
    expect(jsonEncode(body), isA<String>());
  });
}
