import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servory/core/network/api_client.dart';
import 'package:servory/core/providers.dart';
import 'package:servory/features/companies/data/company_repository.dart';

import '../../support/stub_dio.dart';

void main() {
  test('Company.fromApiJson mapeia campos e logo aninhado', () {
    final c = Company.fromApiJson(const {
      'id': 'co1',
      'kind': 'legal',
      'name': 'Servory LTDA',
      'legal_name': 'Servory Serviços',
      'tax_id': '12.345.678/0001-90',
      'logo': {
        'content_type': 'image/png',
        'size_bytes': 4096,
        'sha256': 'abc',
      },
      'version': 5,
    });
    expect(c.id, 'co1');
    expect(c.name, 'Servory LTDA');
    expect(c.hasLogo, isTrue);
    expect(c.logo!.sizeBytes, 4096);
    expect(c.version, 5);
  });

  test('Company.fromApiJson sem logo -> hasLogo false', () {
    final c = Company.fromApiJson(const {'id': 'co2', 'name': 'X'});
    expect(c.hasLogo, isFalse);
    expect(c.kind, 'legal');
  });

  test('create: POST /v1/companies com o corpo da spec', () async {
    final stub = StubDio((req) {
      if (req.method == 'POST') {
        return (status: 201, body: {'id': 'co9', 'name': 'Nova', 'version': 1});
      }
      return (status: 200, body: {'companies': <dynamic>[]});
    });
    final container = _container(stub);
    addTearDown(container.dispose);

    await container.read(companyRepositoryProvider).create(
      kind: 'legal',
      name: 'Nova',
      taxId: '00',
    );
    final post = stub.requests.firstWhere((r) => r.method == 'POST');
    expect(post.path, '/v1/companies');
    final body = post.data as Map;
    expect(body['name'], 'Nova');
    expect(body['kind'], 'legal');
    expect(body.containsKey('person_user_id'), isFalse);
  });

  test('update manda version; delete faz DELETE', () async {
    final stub = StubDio((req) {
      if (req.method == 'PATCH') {
        return (status: 200, body: {'id': 'co1', 'name': 'Y', 'version': 2});
      }
      if (req.method == 'DELETE') return (status: 204, body: '');
      return (status: 200, body: {'companies': <dynamic>[]});
    });
    final container = _container(stub);
    addTearDown(container.dispose);
    final repo = container.read(companyRepositoryProvider);

    await repo.update(
      'co1',
      version: 1,
      kind: 'legal',
      name: 'Y',
      legalName: '',
      taxId: '',
      taxRegime: '',
      phone: '',
      email: '',
      address: '',
      notes: '',
    );
    final patch = stub.requests.firstWhere((r) => r.method == 'PATCH');
    expect(patch.path, '/v1/companies/co1');
    expect((patch.data as Map)['version'], 1);

    await repo.delete('co1');
    expect(
      stub.requests.any(
        (r) => r.method == 'DELETE' && r.path == '/v1/companies/co1',
      ),
      isTrue,
    );
  });

  test('membros: add faz POST {user_id}; setPrimary PATCH; remove DELETE', () async {
    final stub = StubDio((req) {
      if (req.method == 'POST') {
        return (status: 201, body: {'user_id': 'u1', 'name': 'Ana', 'is_primary': false});
      }
      if (req.method == 'PATCH') {
        return (status: 200, body: {'user_id': 'u1', 'name': 'Ana', 'is_primary': true});
      }
      if (req.method == 'DELETE') return (status: 204, body: '');
      return (status: 200, body: {'members': <dynamic>[]});
    });
    final container = _container(stub);
    addTearDown(container.dispose);
    final repo = container.read(companyRepositoryProvider);

    await repo.addMember('co1', userId: 'u1');
    final post = stub.requests.firstWhere((r) => r.method == 'POST');
    expect(post.path, '/v1/companies/co1/members');
    expect((post.data as Map)['user_id'], 'u1');

    await repo.setMemberPrimary('co1', 'u1', isPrimary: true);
    final patch = stub.requests.firstWhere((r) => r.method == 'PATCH');
    expect(patch.path, '/v1/companies/co1/members/u1');
    expect((patch.data as Map)['is_primary'], true);

    await repo.removeMember('co1', 'u1');
    expect(
      stub.requests.any(
        (r) => r.method == 'DELETE' && r.path == '/v1/companies/co1/members/u1',
      ),
      isTrue,
    );
  });

  test('setLogo: POST multipart em .../logo', () async {
    final stub = StubDio((req) {
      if (req.method == 'POST') {
        return (status: 200, body: {'id': 'co1', 'name': 'X', 'version': 2});
      }
      return (status: 200, body: {'companies': <dynamic>[]});
    });
    final container = _container(stub);
    addTearDown(container.dispose);

    await container.read(companyRepositoryProvider).setLogo(
      'co1',
      bytes: Uint8List.fromList(utf8.encode('png-bytes')),
      filename: 'logo.png',
    );
    final post = stub.requests.firstWhere((r) => r.method == 'POST');
    expect(post.path, '/v1/companies/co1/logo');
    expect(post.data, isA<FormData>());
  });
}

ProviderContainer _container(StubDio stub) => ProviderContainer(
  overrides: [apiClientProvider.overrideWithValue(_FakeApiClient(stub.dio))],
);

class _FakeApiClient implements ApiClient {
  _FakeApiClient(this.businessDio);
  @override
  final Dio businessDio;
  @override
  Dio get authDio => businessDio;
}
