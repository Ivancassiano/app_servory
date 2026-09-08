import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servory/core/connectivity/connectivity_provider.dart';
import 'package:servory/core/db/app_database.dart';
import 'package:servory/core/network/api_client.dart';
import 'package:servory/core/providers.dart';
import 'package:servory/features/auth/application/session_controller.dart';
import 'package:servory/features/items/data/item_mapper.dart';
import 'package:servory/features/items/data/item_repository.dart';
import 'package:servory/features/sync/application/sync_provider.dart';

import '../../support/stub_dio.dart';

void main() {
  test('itemFromApiJson lê location_id + campos mascaráveis', () {
    final it = itemFromApiJson(const {
      'id': 'i1',
      'client_id': 'c1',
      'location_id': 'loc1',
      'item_type_id': 't1',
      'name': 'Split 1',
      'serial_number': 'SN-9',
      'cost': null, // sem permissão de leitura
      'version': 3,
    }, organizationId: 'org1');
    expect(it.name, 'Split 1');
    expect(it.locationId, 'loc1');
    expect(it.itemTypeId, 't1');
    expect(it.serialNumber, 'SN-9');
    expect(it.cost, isNull);
    expect(it.isActive, isTrue); // ausente = ativo
    expect(it.version, 3);
  });

  test('itemFromApiJson lê is_active', () {
    final it = itemFromApiJson(const {
      'id': 'i1',
      'client_id': 'c1',
      'name': 'X',
      'is_active': false,
    }, organizationId: 'org1');
    expect(it.isActive, isFalse);
  });

  test('itemCreateBody manda client_id, name e location_id', () {
    final body = itemCreateBody(clientId: 'c1', name: 'X', locationId: 'loc1');
    expect(body['client_id'], 'c1');
    expect(body['name'], 'X');
    expect(body['location_id'], 'loc1');
  });

  test('itemUpdateBody sempre inclui location_id (null desvincula)', () {
    final body = itemUpdateBody(name: 'X');
    expect(body.containsKey('location_id'), isTrue);
    expect(body['location_id'], isNull);
  });

  test('itemUpdateBody manda is_active só quando passado', () {
    expect(itemUpdateBody(name: 'X'), isNot(contains('is_active')));
    expect(
      itemUpdateBody(name: 'X', isActive: false),
      containsPair('is_active', false),
    );
  });

  group('LocalFirstItemRepository (app)', () {
    late AppDatabase db;
    late StubDio stub;

    Future<ProviderContainer> build({
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

    test('online: cria via REST, aquece o cache, sem outbox', () async {
      final c = await build(
        online: true,
        handler: (req) {
          if (req.path == '/v1/items' && req.method == 'POST') {
            return (
              status: 201,
              body: {
                'id': 'srv-1',
                'client_id': 'c1',
                'name': 'OnlineItem',
                'version': 1,
              },
            );
          }
          return (status: 200, body: {'items': <dynamic>[]});
        },
      );
      final repo = c.read(itemRepositoryProvider);
      final id = await repo.create(
        clientId: 'c1',
        fields: const ItemFields(name: 'OnlineItem'),
      );
      expect(id, 'srv-1');
      final rows = await db.select(db.localItems).get();
      expect(rows.single.name, 'OnlineItem');
      expect(rows.single.syncStatus, 'synced');
      expect(await db.select(db.syncOutbox).get(), isEmpty);
    });

    test('offline: grava local pendente + outbox create com location_id', () async {
      final c = await build(
        online: false,
        handler: (req) => (status: 200, body: {'items': <dynamic>[]}),
      );
      final repo = c.read(itemRepositoryProvider);
      final id = await repo.create(
        clientId: 'c1',
        fields: const ItemFields(name: 'OfflineItem', locationId: 'loc1'),
      );
      final rows = await db.select(db.localItems).get();
      expect(rows.single.id, id);
      expect(rows.single.locationId, 'loc1');
      expect(rows.single.syncStatus, 'pending');
      final outbox = await db.select(db.syncOutbox).get();
      expect(outbox.single.entityType, 'item');
      expect(outbox.single.operationType, 'create');
      expect(outbox.single.payload, contains('loc1'));
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
