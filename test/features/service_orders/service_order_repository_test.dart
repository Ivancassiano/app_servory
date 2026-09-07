import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servory/core/connectivity/connectivity_provider.dart';
import 'package:servory/core/db/app_database.dart';
import 'package:servory/core/network/api_client.dart';
import 'package:servory/core/providers.dart';
import 'package:servory/features/auth/application/session_controller.dart';
import 'package:servory/features/service_orders/data/service_order_repository.dart';
import 'package:servory/features/sync/application/sync_provider.dart';

import '../../support/stub_dio.dart';

void main() {
  group('LocalFirstServiceOrderRepository.addItem', () {
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

    test('online: manda item_id no POST /items', () async {
      Object? postData;
      final c = await build(
        online: true,
        handler: (req) {
          if (req.path == '/v1/service-orders/so1/items' &&
              req.method == 'POST') {
            postData = req.data;
            return (
              status: 201,
              body: {
                'id': 'row-1',
                'service_order_id': 'so1',
                'item_id': 'item-9',
                'version': 1,
              },
            );
          }
          return (status: 200, body: <String, dynamic>{});
        },
      );
      final repo = c.read(serviceOrderRepositoryProvider);
      final id = await repo.addItem(orderId: 'so1', itemId: 'item-9');
      expect(id, 'row-1');
      expect(postData, isA<Map>());
      expect((postData as Map)['item_id'], 'item-9');
      final rows = await db.select(db.localServiceOrderItems).get();
      expect(rows.single.itemId, 'item-9');
    });

    test('offline: enfileira create com item_id no payload', () async {
      final c = await build(
        online: false,
        handler: (req) => (status: 200, body: <String, dynamic>{}),
      );
      final repo = c.read(serviceOrderRepositoryProvider);
      await repo.addItem(orderId: 'so1', itemId: 'item-9');
      final rows = await db.select(db.localServiceOrderItems).get();
      expect(rows.single.itemId, 'item-9');
      final outbox = await db.select(db.syncOutbox).get();
      expect(outbox.single.entityType, 'service_order_item');
      expect(outbox.single.operationType, 'create');
      expect(outbox.single.payload, contains('item-9'));
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
