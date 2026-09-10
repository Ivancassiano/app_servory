import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:servory/features/roles/data/roles_api.dart';

import '../../support/stub_dio.dart';

void main() {
  test('Role.allowedKeys ignora os deny', () {
    final r = Role.fromJson(const {
      'id': 'r1',
      'key': 'custom',
      'name': 'Custom',
      'is_system': false,
      'permissions': [
        {'key': 'client.read', 'effect': 'allow'},
        {'key': 'client.delete', 'effect': 'deny'},
      ],
    });
    expect(r.allowedKeys, {'client.read'});
  });

  test('listCatalog lê a chave "permissions"', () async {
    final stub = StubDio(
      (_) => (
        status: 200,
        body: {
          'permissions': [
            {
              'key': 'client.read',
              'resource': 'client',
              'action': 'read',
              'is_field': false,
              'description': 'Ver clientes',
            },
          ],
        },
      ),
    );
    final cat = await RolesApi(stub.dio).listCatalog();
    expect(cat.single.key, 'client.read');
    expect(cat.single.resource, 'client');
  });

  test('setRolePermissions manda a allow-list em PUT', () async {
    final stub = StubDio((_) => (status: 200, body: <String, Object>{}));
    await RolesApi(
      stub.dio,
    ).setRolePermissions('r9', {'client.read', 'client.update'});

    final req = stub.lastRequest;
    expect(req.method, 'PUT');
    expect(req.path, '/v1/roles/r9/permissions');
    final body = jsonDecode(jsonEncode(req.data)) as Map<String, dynamic>;
    final perms = (body['permissions'] as List).cast<Map<String, dynamic>>();
    expect(perms, hasLength(2));
    expect(perms.every((p) => p['effect'] == 'allow'), isTrue);
    expect(
      perms.map((p) => p['key']).toSet(),
      {'client.read', 'client.update'},
    );
  });

  test('createRole manda key/name/description', () async {
    final stub = StubDio(
      (_) => (
        status: 201,
        body: {'id': 'new1', 'key': 'k', 'name': 'Vendas', 'is_system': false},
      ),
    );
    final role = await RolesApi(
      stub.dio,
    ).createRole(key: 'vendas_x', name: 'Vendas', description: 'time externo');
    expect(role.id, 'new1');
    final body = jsonDecode(jsonEncode(stub.lastRequest.data));
    expect(body, {
      'key': 'vendas_x',
      'name': 'Vendas',
      'description': 'time externo',
    });
  });
}
