import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servory/core/db/app_database.dart';
import 'package:servory/core/network/api_client.dart';
import 'package:servory/core/providers.dart';
import 'package:servory/features/auth/application/session_controller.dart';
import 'package:servory/features/labels/data/label_batch_repository.dart';
import 'package:servory/features/sync/application/sync_provider.dart';

import '../../support/stub_dio.dart';

void main() {
  test('app: create faz POST e grava lote + códigos no drift', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    RequestOptions? posted;
    final stub = StubDio((req) {
      if (req.method == 'POST' && req.path == '/v1/qr-batches') {
        posted = req;
        return (
          status: 201,
          body: {
            'batch': {
              'id': 'b1',
              'label': 'Lote A',
              'quantity': 2,
              'status': 'created',
              'version': 1,
            },
            'codes': [
              {'id': 'q1', 'status': 'available', 'batch_id': 'b1'},
              {'id': 'q2', 'status': 'available', 'batch_id': 'b1'},
            ],
          },
        );
      }
      return (status: 200, body: {'results': <dynamic>[]});
    });
    final c = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        apiClientProvider.overrideWithValue(_FakeApiClient(stub.dio)),
        sessionControllerProvider.overrideWith(_FakeSession.new),
      ],
    );
    addTearDown(c.dispose);

    final batch = await c.read(labelBatchRepositoryProvider).create(
          label: 'Lote A',
          quantity: 2,
        );
    expect(batch.id, 'b1');
    expect((posted!.data as Map)['quantity'], 2);

    final batches = await db.select(db.localQrBatches).get();
    expect(batches.single.label, 'Lote A');
    final codes = await db.select(db.localQrCodes).get();
    expect(codes.map((e) => e.id).toSet(), {'q1', 'q2'});
  });

  test('qrConflictCountProvider conta as etiquetas em conflito', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final stub = StubDio((_) => (status: 200, body: <String, dynamic>{}));
    final c = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        apiClientProvider.overrideWithValue(_FakeApiClient(stub.dio)),
        sessionControllerProvider.overrideWith(_FakeSession.new),
      ],
    );
    addTearDown(c.dispose);

    final seen = <int>[];
    c.listen(
      qrConflictCountProvider,
      (_, next) {
        if (next.hasValue) seen.add(next.value!);
      },
      fireImmediately: true,
    );
    await pumpEventQueue();
    expect(seen.last, 0);

    for (final r in [
      ('x', 'conflict'),
      ('y', 'conflict'),
      ('z', 'synced'),
    ]) {
      await db.into(db.localQrCodes).insert(
            LocalQrCodesCompanion.insert(
              id: r.$1,
              organizationId: 'org1',
              status: 'assigned',
              syncStatus: Value(r.$2),
              localUpdatedAt: DateTime.now(),
            ),
          );
    }
    await pumpEventQueue();
    expect(seen.last, 2);
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
