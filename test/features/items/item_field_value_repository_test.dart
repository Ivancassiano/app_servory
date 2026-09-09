import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servory/core/connectivity/connectivity_provider.dart';
import 'package:servory/core/db/app_database.dart';
import 'package:servory/core/network/api_client.dart';
import 'package:servory/core/providers.dart';
import 'package:servory/features/auth/application/session_controller.dart';
import 'package:servory/features/items/data/item_field_value_repository.dart';
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

  test('online: PUT /v1/items/{id}/fields e regrava o cache', () async {
    Object? putData;
    final c = await build(
      online: true,
      handler: (req) {
        if (req.method == 'PUT') {
          putData = req.data;
          return (
            status: 200,
            body: {
              'field_values': [
                {
                  'id': 'v1',
                  'item_id': 'i1',
                  'field_def_id': 'd1',
                  'value_text': '220',
                  'version': 1,
                },
              ],
            },
          );
        }
        return (status: 200, body: {});
      },
    );
    final repo = c.read(itemFieldValueRepositoryProvider);
    await repo.setValues('i1', {
      'd1': const TypedFieldValue(text: '220'),
      'd2': const TypedFieldValue(boolean: true),
    });
    expect((putData as Map)['values'], hasLength(2));
    final rows = await db.select(db.localItemFieldValues).get();
    expect(rows.single.fieldDefId, 'd1');
    expect(rows.single.valueText, '220');
    expect(rows.single.syncStatus, 'synced');
  });

  test('offline: enfileira create/update/delete por linha', () async {
    final c = await build(
      online: false,
      handler: (req) => (status: 200, body: {}),
    );
    // valor JÁ sincronizado (tem version) que vai sumir do conjunto novo
    await db.into(db.localItemFieldValues).insert(
          LocalItemFieldValuesCompanion.insert(
            id: 'old',
            organizationId: 'org1',
            itemId: 'i1',
            fieldDefId: 'd-antigo',
            valueText: const Value('x'),
            version: const Value(3),
            localUpdatedAt: DateTime.now(),
          ),
        );
    final repo = c.read(itemFieldValueRepositoryProvider);
    await repo.setValues('i1', {
      'd1': const TypedFieldValue(number: 12.5),
    });

    final vals = await db.select(db.localItemFieldValues).get();
    final created = vals.firstWhere((v) => v.fieldDefId == 'd1');
    expect(created.valueNumber, 12.5);
    expect(created.syncStatus, 'pending');
    final removed = vals.firstWhere((v) => v.fieldDefId == 'd-antigo');
    expect(removed.deleted, isTrue);

    final ops = await db.select(db.syncOutbox).get();
    expect(ops.map((o) => o.entityType).toSet(), {'item_field_value'});
    expect(ops.map((o) => o.operationType).toSet(), {'create', 'delete'});
  });

  test('offline: editar valor ainda não sincronizado reescreve o create '
      '(não gera update sem base_version)', () async {
    final c = await build(
      online: false,
      handler: (req) => (status: 200, body: {}),
    );
    final repo = c.read(itemFieldValueRepositoryProvider);

    // 1ª gravação offline → create
    await repo.setValues('i1', {'d1': const TypedFieldValue(number: 1)});
    // 2ª gravação antes de sincronizar → NÃO pode virar update sem version
    await repo.setValues('i1', {'d1': const TypedFieldValue(number: 2)});

    final vals = await db.select(db.localItemFieldValues).get();
    expect(vals.single.valueNumber, 2);
    expect(vals.single.version, isNull);

    final ops = await db.select(db.syncOutbox).get();
    expect(
      ops.map((o) => o.operationType),
      ['create'],
      reason: 'uma operação create com o valor final, sem update',
    );
    expect(ops.single.baseVersion, isNull);
    expect(
      (jsonDecode(ops.single.payload) as Map)['value'],
      2,
    );
  });

  test('offline: limpar valor ainda não sincronizado só desfaz local', () async {
    final c = await build(
      online: false,
      handler: (req) => (status: 200, body: {}),
    );
    final repo = c.read(itemFieldValueRepositoryProvider);

    await repo.setValues('i1', {'d1': const TypedFieldValue(number: 1)});
    await repo.setValues('i1', {'d1': const TypedFieldValue()}); // limpa

    expect(await db.select(db.localItemFieldValues).get(), isEmpty);
    expect(await db.select(db.syncOutbox).get(), isEmpty);
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
