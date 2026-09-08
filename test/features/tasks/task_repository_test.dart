import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servory/core/connectivity/connectivity_provider.dart';
import 'package:servory/core/db/app_database.dart';
import 'package:servory/core/network/api_client.dart';
import 'package:servory/core/providers.dart';
import 'package:servory/features/auth/application/session_controller.dart';
import 'package:servory/features/tasks/data/task_mapper.dart';
import 'package:servory/features/tasks/data/task_repository.dart';
import 'package:servory/features/sync/application/sync_provider.dart';

import '../../support/stub_dio.dart';

void main() {
  test('taskFromApiJson lê campos planos + status', () {
    final t = taskFromApiJson(const {
      'id': 't1',
      'client_id': 'c1',
      'description': 'Trocar filtros',
      'status': 'open',
      'scheduled_all_day': true,
      'version': 3,
    }, organizationId: 'org1');
    expect(t.description, 'Trocar filtros');
    expect(t.clientId, 'c1');
    expect(t.scheduledAllDay, true);
    expect(t.version, 3);
  });

  test('taskTargetsFromApiJson deriva as linhas de targets', () {
    final rows = taskTargetsFromApiJson(const {
      'id': 't1',
      'targets': [
        {'location_id': 'l1', 'item_id': null},
        {'location_id': 'l1', 'item_id': 'i1'},
        {'location_id': null, 'item_id': 'i2'},
      ],
    });
    expect(rows.length, 3);
    expect(rows[1].locationId.value, 'l1');
    expect(rows[1].itemId.value, 'i1');
  });

  test('taskCreateBody aninha targets e client_id', () {
    final body = taskCreateBody(
      clientId: 'c1',
      description: 'X',
      targets: const [TaskTargetInput(locationId: 'l1', itemId: 'i1')],
    );
    expect(body['client_id'], 'c1');
    expect((body['targets'] as List).single, containsPair('location_id', 'l1'));
  });

  test('offline: grava tarefa + alvos + outbox create', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final stub = StubDio((req) => (status: 200, body: {'tasks': <dynamic>[]}));
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

    final repo = c.read(taskRepositoryProvider);
    final id = await repo.create(
      clientId: 'c1',
      fields: const TaskFields(
        description: 'Trocar filtros',
        targets: [
          TaskTargetInput(locationId: 'l1'),
          TaskTargetInput(locationId: 'l1', itemId: 'i1'),
        ],
      ),
    );

    final task = await (db.select(
      db.localTasks,
    )..where((t) => t.id.equals(id))).getSingle();
    expect(task.description, 'Trocar filtros');
    expect(task.syncStatus, 'pending');

    final targets = await (db.select(
      db.localTaskTargets,
    )..where((t) => t.taskId.equals(id))).get();
    expect(targets.length, 2);

    final outbox = await db.select(db.syncOutbox).getSingle();
    expect(outbox.entityType, 'task');
    expect(outbox.operationType, 'create');
    final payload = jsonDecode(outbox.payload) as Map<String, dynamic>;
    expect((payload['targets'] as List).length, 2);
  });

  test('offline: transition complete marca done + enfileira ação', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final stub = StubDio((req) => (status: 200, body: {'tasks': <dynamic>[]}));
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

    final repo = c.read(taskRepositoryProvider);
    final id = await repo.create(
      clientId: 'c1',
      fields: const TaskFields(description: 'X'),
    );
    await repo.transition(
      id: id,
      baseVersion: 1,
      action: 'complete',
      generatedOrderId: 'so1',
    );

    final task = await (db.select(
      db.localTasks,
    )..where((t) => t.id.equals(id))).getSingle();
    expect(task.status, 'done');
    expect(task.generatedOrderId, 'so1');

    final ops = await db.select(db.syncOutbox).get();
    expect(ops.any((o) => o.operationType == 'complete'), true);
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
