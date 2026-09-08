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
  test('locationFromApiJson lê endereço plano', () {
    final l = locationFromApiJson(const {
      'id': 'l1',
      'client_id': 'c1',
      'name': 'Matriz',
      'street': 'Av X',
      'city': 'SP',
      'state': 'SP',
      'version': 2,
    }, organizationId: 'org1');
    expect(l.name, 'Matriz');
    expect(l.street, 'Av X');
    expect(l.clientId, 'c1');
    expect(l.version, 2);
  });

  test('locationCreateBody aninha o endereço sob address', () {
    final body = locationCreateBody(
      clientId: 'c1',
      name: 'Filial',
      address: const LocationAddressInput(street: 'Rua B', city: 'Rio'),
    );
    expect(body['client_id'], 'c1');
    expect(body['name'], 'Filial');
    expect(body['address'], containsPair('street', 'Rua B'));
  });

  test('offline: grava local pendente + outbox create', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final stub = StubDio(
      (req) => (status: 200, body: {'locations': <dynamic>[]}),
    );
    final c = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        apiClientProvider.overrideWithValue(_FakeApiClient(stub.dio)),
        isOnlineProvider.overrideWith((ref) => Stream.value(false)),
        sessionControllerProvider.overrideWith(_FakeSession.new),
      ],
    );
    addTearDown(c.dispose);
    addTearDown(db.close);
    c.listen(isOnlineProvider, (_, _) {});
    await pumpEventQueue();

    final repo = c.read(locationRepositoryProvider);
    final id = await repo.create(
      clientId: 'c1',
      fields: const LocationFields(
        name: 'Matriz',
        address: LocationAddressInput(street: 'Av X'),
      ),
    );
    final rows = await db.select(db.localLocations).get();
    expect(rows.single.id, id);
    expect(rows.single.name, 'Matriz');
    expect(rows.single.street, 'Av X');
    expect(rows.single.syncStatus, 'pending');
    final outbox = await db.select(db.syncOutbox).get();
    expect(outbox.single.entityType, 'location');
    expect(outbox.single.operationType, 'create');
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
