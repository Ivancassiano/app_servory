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
  test('itemFromApiJson lê endereço plano + campos mascaráveis', () {
    final it = itemFromApiJson(const {
      'id': 'i1',
      'client_id': 'c1',
      'parent_item_id': 'p1',
      'item_type_id': 't1',
      'name': 'Split 1',
      'street': 'Rua A',
      'city': 'São Paulo',
      'state': 'SP',
      'serial_number': 'SN-9',
      'cost': null, // sem permissão de leitura
      'version': 3,
    }, organizationId: 'org1');
    expect(it.name, 'Split 1');
    expect(it.parentItemId, 'p1');
    expect(it.itemTypeId, 't1');
    expect(it.street, 'Rua A');
    expect(it.serialNumber, 'SN-9');
    expect(it.cost, isNull);
    expect(it.version, 3);
  });

  test('itemCreateBody aninha o endereço sob address', () {
    final body = itemCreateBody(
      clientId: 'c1',
      name: 'X',
      address: const ItemAddressInput(street: 'Rua B', city: 'Rio'),
    );
    expect(body['client_id'], 'c1');
    expect(body['address'], containsPair('street', 'Rua B'));
    expect(body['address'], containsPair('city', 'Rio'));
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

    test('offline: grava local pendente + outbox create', () async {
      final c = await build(
        online: false,
        handler: (req) => (status: 200, body: {'items': <dynamic>[]}),
      );
      final repo = c.read(itemRepositoryProvider);
      final id = await repo.create(
        clientId: 'c1',
        parentItemId: 'p1',
        fields: const ItemFields(name: 'OfflineItem', serialNumber: 'SN-1'),
      );
      final rows = await db.select(db.localItems).get();
      expect(rows.single.id, id);
      expect(rows.single.parentItemId, 'p1');
      expect(rows.single.serialNumber, 'SN-1');
      expect(rows.single.syncStatus, 'pending');
      final outbox = await db.select(db.syncOutbox).get();
      expect(outbox.single.entityType, 'item');
      expect(outbox.single.operationType, 'create');
    });

    test('reparent chama PATCH /v1/items/{id}/parent', () async {
      String? patchPath;
      Object? patchData;
      final c = await build(
        online: true,
        handler: (req) {
          if (req.method == 'PATCH') {
            patchPath = req.path;
            patchData = req.data;
            return (
              status: 200,
              body: {
                'id': 'i1',
                'client_id': 'c1',
                'name': 'X',
                'parent_item_id': 'novo-pai',
                'version': 2,
              },
            );
          }
          return (status: 200, body: {'items': <dynamic>[]});
        },
      );
      final repo = c.read(itemRepositoryProvider);
      await repo.reparent(id: 'i1', baseVersion: 1, parentItemId: 'novo-pai');
      expect(patchPath, '/v1/items/i1/parent');
      expect(patchData, containsPair('parent_item_id', 'novo-pai'));
      final row = await (db.select(
        db.localItems,
      )..where((t) => t.id.equals('i1'))).getSingle();
      expect(row.parentItemId, 'novo-pai');
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
