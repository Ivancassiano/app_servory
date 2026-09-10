import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servory/core/connectivity/connectivity_provider.dart';
import 'package:servory/core/db/app_database.dart';
import 'package:servory/core/network/api_client.dart';
import 'package:servory/core/providers.dart';
import 'package:servory/features/auth/application/session_controller.dart';
import 'package:servory/features/service_orders/data/recommendation_mapper.dart';
import 'package:servory/features/service_orders/data/recommendation_repository.dart';
import 'package:servory/features/sync/application/sync_provider.dart';

import '../../support/stub_dio.dart';

void main() {
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

  test('serviceRecommendationFromApiJson mapeia o shape', () {
    final r = serviceRecommendationFromApiJson(const {
      'id': 'r1',
      'service_order_id': 'so1',
      'service_order_item_id': 'it1',
      'description': 'Trocar correia',
      'priority': 'high',
      'status': 'open',
      'notes': 'antes de 90 dias',
      'version': 2,
    }, organizationId: 'org1');
    expect(r.id, 'r1');
    expect(r.serviceOrderItemId, 'it1');
    expect(r.priority, 'high');
    expect(r.notes, 'antes de 90 dias');
    expect(r.version, 2);
  });

  test('online: POST em .../recommendations e grava o cache local', () async {
    final c = await build(
      online: true,
      handler: (req) {
        if (req.method == 'POST') {
          return (
            status: 201,
            body: {
              'id': 'r9',
              'service_order_id': 'so1',
              'description': 'X',
              'priority': 'medium',
              'status': 'open',
              'version': 1,
            },
          );
        }
        return (status: 200, body: {'recommendations': <dynamic>[]});
      },
    );

    await c.read(recommendationRepositoryProvider).add(
      'so1',
      description: 'X',
      serviceOrderItemId: 'it1',
    );
    final post = stub.requests.firstWhere((r) => r.method == 'POST');
    expect(post.path, '/v1/service-orders/so1/recommendations');
    expect((post.data as Map)['description'], 'X');
    expect((post.data as Map)['service_order_item_id'], 'it1');

    final rows = await db.select(db.localServiceOrderRecommendations).get();
    expect(rows.single.id, 'r9');
    expect(rows.single.syncStatus, 'synced');
  });

  test('offline: enfileira create/update/delete', () async {
    final c = await build(
      online: false,
      handler: (req) => (status: 200, body: {}),
    );
    final repo = c.read(recommendationRepositoryProvider);

    await repo.add('so1', description: 'X', serviceOrderItemId: 'it1');
    final created = (await db.select(db.localServiceOrderRecommendations).get())
        .single;
    expect(created.syncStatus, 'pending');
    expect(created.serviceOrderItemId, 'it1');

    await repo.update(
      'so1',
      created.id,
      version: null,
      description: 'Y',
      priority: 'low',
      status: 'addressed',
      notes: '',
    );
    await repo.delete('so1', created.id);

    final row = (await db.select(db.localServiceOrderRecommendations).get())
        .single;
    expect(row.deleted, isTrue);

    final ops = await db.select(db.syncOutbox).get();
    expect(ops.map((o) => o.entityType).toSet(), {
      'service_order_recommendation',
    });
    expect(ops.map((o) => o.operationType).toList(), [
      'create',
      'update',
      'delete',
    ]);
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
