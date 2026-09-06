import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servory/core/network/api_client.dart';
import 'package:servory/core/providers.dart';
import 'package:servory/features/contacts/data/contact_repository.dart';

import '../../support/stub_dio.dart';

void main() {
  test('Contact.fromApiJson mapeia o shape', () {
    final c = Contact.fromApiJson(const {
      'id': 'ct1',
      'name': 'Maria',
      'role': 'Zeladora',
      'phone': '11999',
      'email': 'm@x.com',
      'is_primary': true,
      'is_whatsapp': true,
      'notes': 'só de manhã',
      'version': 4,
    });
    expect(c.id, 'ct1');
    expect(c.name, 'Maria');
    expect(c.isPrimary, isTrue);
    expect(c.isWhatsapp, isTrue);
    expect(c.version, 4);
  });

  test('Contact.fromApiJson: flags ausentes caem para false', () {
    final c = Contact.fromApiJson(const {'id': 'ct2', 'name': 'X'});
    expect(c.isPrimary, isFalse);
    expect(c.isWhatsapp, isFalse);
    expect(c.role, '');
  });

  test('add: POST no path de contatos do escopo', () async {
    final stub = StubDio((req) {
      if (req.method == 'POST') {
        return (status: 201, body: {'id': 'ct9', 'name': 'Novo', 'version': 1});
      }
      return (status: 200, body: {'contacts': <dynamic>[]});
    });
    final container = ProviderContainer(
      overrides: [apiClientProvider.overrideWithValue(_FakeApiClient(stub.dio))],
    );
    addTearDown(container.dispose);

    await container.read(contactRepositoryProvider).add(
      (ContactScope.client, 'cli1'),
      name: 'Novo',
      isWhatsapp: true,
    );
    final post = stub.requests.firstWhere((r) => r.method == 'POST');
    expect(post.path, '/v1/clients/cli1/contacts');
    expect((post.data as Map)['name'], 'Novo');
    expect((post.data as Map)['is_whatsapp'], true);
  });

  test('update manda version; delete faz DELETE no contactId (escopo local)', () async {
    final stub = StubDio((req) {
      if (req.method == 'PATCH') {
        return (status: 200, body: {'id': 'ct1', 'name': 'Y', 'version': 3});
      }
      if (req.method == 'DELETE') return (status: 204, body: '');
      return (status: 200, body: {'contacts': <dynamic>[]});
    });
    final container = ProviderContainer(
      overrides: [apiClientProvider.overrideWithValue(_FakeApiClient(stub.dio))],
    );
    addTearDown(container.dispose);
    final repo = container.read(contactRepositoryProvider);
    const key = (ContactScope.location, 'loc1');

    await repo.update(
      key,
      'ct1',
      version: 2,
      name: 'Y',
      role: '',
      phone: '',
      email: '',
      isPrimary: false,
      isWhatsapp: false,
      notes: '',
    );
    final patch = stub.requests.firstWhere((r) => r.method == 'PATCH');
    expect(patch.path, '/v1/locations/loc1/contacts/ct1');
    expect((patch.data as Map)['version'], 2);

    await repo.delete(key, 'ct1');
    expect(
      stub.requests.any(
        (r) =>
            r.method == 'DELETE' &&
            r.path == '/v1/locations/loc1/contacts/ct1',
      ),
      isTrue,
    );
  });
}

class _FakeApiClient implements ApiClient {
  _FakeApiClient(this.businessDio);
  @override
  final Dio businessDio;
  @override
  Dio get authDio => businessDio;
}
