import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servory/core/connectivity/connectivity_provider.dart';
import 'package:servory/core/db/app_database.dart';
import 'package:servory/core/network/api_client.dart';
import 'package:servory/core/providers.dart';
import 'package:servory/features/auth/application/session_controller.dart';
import 'package:servory/features/equipments/data/equipment_mapper.dart';
import 'package:servory/features/equipments/data/equipment_repository.dart';
import 'package:servory/features/equipments/data/equipment_type_mapper.dart';
import 'package:servory/features/sync/application/sync_provider.dart';

import '../../support/stub_dio.dart';

void main() {
  test('equipmentCreateBody exige location_id + equipment_type_id', () {
    final body = equipmentCreateBody(
      locationId: 'loc1',
      equipmentTypeId: 'type1',
      name: 'Forno',
      brand: '',
      model: '',
      notes: '',
    );
    expect(body['location_id'], 'loc1');
    expect(body['equipment_type_id'], 'type1');
    expect(body['name'], 'Forno');
  });

  test('equipmentTypeFromApiJson mapeia o shape REST', () {
    final t = equipmentTypeFromApiJson(
      const {'id': 't1', 'name': 'Forno', 'description': 'd', 'version': 1},
      organizationId: 'org1',
    );
    expect(t.id, 't1');
    expect(t.name, 'Forno');
    expect(t.organizationId, 'org1');
  });

  group('EquipmentRepository.create', () {
    late AppDatabase db;
    late StubDio stub;

    Future<ProviderContainer> container({
      required bool online,
      required StubHandler handler,
    }) async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      stub = StubDio(handler);
      final c = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          apiClientProvider.overrideWithValue(_FakeApiClient(stub.dio)),
          isOnlineProvider.overrideWith((ref) => Stream.value(online)),
          sessionControllerProvider.overrideWith(_FakeSession.new),
        ],
      );
      addTearDown(c.dispose);
      addTearDown(db.close);
      c.listen(isOnlineProvider, (_, _) {});
      await pumpEventQueue();
      return c;
    }

    test('web: POST /v1/equipments com os campos obrigatórios', () async {
      RequestOptions? posted;
      final c = await container(
        online: true,
        handler: (req) {
          if (req.method == 'POST') {
            posted = req;
            return (
              status: 201,
              body: {
                'id': 'srv-eq',
                'location_id': 'loc1',
                'equipment_type_id': 'type1',
                'name': 'Forno',
                'version': 1,
              },
            );
          }
          return (status: 200, body: {'equipments': <dynamic>[]});
        },
      );
      // força a impl remota
      final repo = RemoteEquipmentRepository(stub.dio, 'org1');
      addTearDown(repo.dispose);
      final id = await repo.create(
        locationId: 'loc1',
        equipmentTypeId: 'type1',
        name: 'Forno',
        brand: '',
        model: '',
        notes: '',
      );
      expect(id, 'srv-eq');
      expect(posted?.path, '/v1/equipments');
      expect((posted?.data as Map)['location_id'], 'loc1');
      c.dispose();
    });

    test('app offline: grava local pending + outbox create', () async {
      final c = await container(
        online: false,
        handler: (req) => (status: 200, body: {'results': <dynamic>[]}),
      );
      final id = await c.read(equipmentRepositoryProvider).create(
        locationId: 'loc1',
        equipmentTypeId: 'type1',
        name: 'Forno',
        brand: 'X',
        model: 'Y',
        notes: '',
      );
      final rows = await db.select(db.localEquipments).get();
      expect(rows.single.id, id);
      expect(rows.single.locationId, 'loc1');
      expect(rows.single.syncStatus, 'pending');
      final outbox = await db.select(db.syncOutbox).get();
      expect(outbox.single.operationType, 'create');
      expect(outbox.single.entityType, 'equipment');
    });
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
