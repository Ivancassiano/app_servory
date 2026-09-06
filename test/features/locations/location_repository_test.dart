import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servory/core/connectivity/connectivity_provider.dart';
import 'package:servory/core/db/app_database.dart';
import 'package:servory/core/network/api_client.dart';
import 'package:servory/core/providers.dart';
import 'package:servory/features/auth/application/session_controller.dart';
import 'package:servory/features/locations/data/location_mapper.dart';
import 'package:servory/features/locations/data/location_repository.dart';
import 'package:servory/features/sync/application/sync_provider.dart';

import '../../support/stub_dio.dart';

void main() {
  test('locationCreateBody: client_id obrigatório, parent opcional omitido', () {
    expect(
      locationCreateBody(
        clientId: 'c1',
        name: 'Filial',
        contactPerson: '',
        phone: '',
        notes: '',
      ),
      {
        'client_id': 'c1',
        'name': 'Filial',
        'contact_person': '',
        'phone': '',
        'notes': '',
        'address': {
          'postal_code': '',
          'street': '',
          'number': '',
          'complement': '',
          'district': '',
          'city': '',
          'state': '',
        },
      },
    );
    expect(
      locationCreateBody(
        clientId: 'c1',
        parentLocationId: 'p1',
        name: 'Sala',
        contactPerson: '',
        phone: '',
        notes: '',
      )['parent_location_id'],
      'p1',
    );
  });

  test('locationUpdateBody aninha o endereço sob address', () {
    final body = locationUpdateBody(
      name: 'Filial',
      contactPerson: '',
      phone: '',
      notes: '',
      address: const LocationAddressInput(
        postalCode: '01310-100',
        street: 'Av. Paulista',
        number: '1000',
        city: 'São Paulo',
        state: 'SP',
      ),
    );
    expect(body['address'], {
      'postal_code': '01310-100',
      'street': 'Av. Paulista',
      'number': '1000',
      'complement': '',
      'district': '',
      'city': 'São Paulo',
      'state': 'SP',
    });
  });

  test('web: create faz POST /v1/locations', () async {
    RequestOptions? posted;
    final stub = StubDio((req) {
      if (req.method == 'POST') {
        posted = req;
        return (
          status: 201,
          body: {'id': 'srv-loc', 'client_id': 'c1', 'name': 'Filial', 'version': 1},
        );
      }
      return (status: 200, body: {'locations': <dynamic>[]});
    });
    final repo = RemoteLocationRepository(stub.dio, 'org1');
    addTearDown(repo.dispose);
    final id = await repo.create(
      clientId: 'c1',
      name: 'Filial',
      contactPerson: '',
      phone: '',
      notes: '',
    );
    expect(id, 'srv-loc');
    expect(posted?.path, '/v1/locations');
    expect((posted?.data as Map)['client_id'], 'c1');
  });

  test('app offline: grava local pending + outbox', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final stub = StubDio((_) => (status: 200, body: {'results': <dynamic>[]}));
    final c = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        apiClientProvider.overrideWithValue(_FakeApiClient(stub.dio)),
        isOnlineProvider.overrideWith((ref) => Stream.value(false)),
        sessionControllerProvider.overrideWith(_FakeSession.new),
      ],
    );
    addTearDown(c.dispose);
    c.listen(isOnlineProvider, (_, _) {});
    await pumpEventQueue();

    final id = await c.read(locationRepositoryProvider).create(
      clientId: 'c1',
      name: 'Filial',
      contactPerson: 'Ana',
      phone: '',
      notes: '',
    );
    final rows = await db.select(db.localLocations).get();
    expect(rows.single.id, id);
    expect(rows.single.clientId, 'c1');
    expect(rows.single.syncStatus, 'pending');
    final outbox = await db.select(db.syncOutbox).get();
    expect(outbox.single.operationType, 'create');
    expect(outbox.single.entityType, 'location');
  });
}

class _FakeApiClient implements ApiClient {
  _FakeApiClient(this.businessDio);
  @override
  final Dio businessDio;
  @override
  Dio get authDio => businessDio;
}

class _FakeSession extends SessionController {
  @override
  SessionState build() =>
      const SessionAuthenticated(userId: 'u1', organizationId: 'org1');
}
