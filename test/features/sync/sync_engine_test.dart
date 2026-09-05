import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:servory/core/db/app_database.dart';
import 'package:servory/features/sync/application/sync_engine.dart';
import 'package:servory/features/sync/data/sync_api.dart';

class MockSyncApi extends Mock implements SyncApi {}

void main() {
  setUpAll(() {
    registerFallbackValue(<SyncOperationRequest>[]);
  });

  late AppDatabase db;
  late MockSyncApi api;
  late SyncEngine engine;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    api = MockSyncApi();
    engine = SyncEngine(api: api, db: db, organizationId: 'org1');
  });

  tearDown(() => db.close());

  test('bootstrap pagina os 3 tipos e popula as tabelas locais', () async {
    when(
      () => api.bootstrap(
        entityType: 'client',
        page: any(named: 'page'),
      ),
    ).thenAnswer(
      (_) async => SyncBootstrapPage(
        items: [
          {'id': 'c1', 'kind': 'legal', 'name': 'ClimaTech', 'version': 1},
        ],
        total: 1,
        page: 1,
        size: 100,
        cursor: 5,
      ),
    );
    when(
      () => api.bootstrap(
        entityType: 'location',
        page: any(named: 'page'),
      ),
    ).thenAnswer(
      (_) async => const SyncBootstrapPage(
        items: [],
        total: 0,
        page: 1,
        size: 100,
        cursor: 5,
      ),
    );
    when(
      () => api.bootstrap(
        entityType: 'equipment',
        page: any(named: 'page'),
      ),
    ).thenAnswer(
      (_) async => const SyncBootstrapPage(
        items: [],
        total: 0,
        page: 1,
        size: 100,
        cursor: 5,
      ),
    );

    await engine.bootstrap();

    final clients = await db.select(db.localClients).get();
    expect(clients, hasLength(1));
    expect(clients.single.name, 'ClimaTech');
    expect(clients.single.syncStatus, 'synced');

    final cursorRow = await (db.select(
      db.localSyncState,
    )..where((t) => t.organizationId.equals('org1'))).getSingle();
    expect(cursorRow.cursor, 5);
  });

  test('pull aplica update e delete, avança o cursor', () async {
    when(() => api.pull(cursor: 0, limit: any(named: 'limit'))).thenAnswer(
      (_) async => const SyncPullResult(
        entities: [
          SyncEntityChange(
            entityType: 'client',
            entityId: 'c1',
            deleted: false,
            data: {
              'id': 'c1',
              'kind': 'legal',
              'name': 'ClimaTech',
              'version': 1,
            },
          ),
        ],
        nextCursor: 10,
      ),
    );
    when(() => api.pull(cursor: 10, limit: any(named: 'limit'))).thenAnswer(
      (_) async => const SyncPullResult(
        entities: [
          SyncEntityChange(entityType: 'client', entityId: 'c1', deleted: true),
        ],
        nextCursor: 11,
      ),
    );
    when(() => api.pull(cursor: 11, limit: any(named: 'limit'))).thenAnswer(
      (_) async => const SyncPullResult(entities: [], nextCursor: 11),
    );

    await engine.pull();

    final client = await (db.select(
      db.localClients,
    )..where((t) => t.id.equals('c1'))).getSingle();
    expect(client.deleted, isTrue);

    final cursorRow = await (db.select(
      db.localSyncState,
    )..where((t) => t.organizationId.equals('org1'))).getSingle();
    expect(cursorRow.cursor, 11);
    verify(() => api.pull(cursor: 0, limit: any(named: 'limit'))).called(1);
    verify(() => api.pull(cursor: 10, limit: any(named: 'limit'))).called(1);
    verify(() => api.pull(cursor: 11, limit: any(named: 'limit'))).called(1);
  });

  test(
    'push: accepted atualiza version e drena a outbox; conflict marca e drena; erro mantém na outbox',
    () async {
      final now = DateTime.now();
      await db.batch((b) {
        b.insertAll(db.localClients, [
          LocalClientsCompanion.insert(
            id: 'c1',
            organizationId: 'org1',
            kind: 'legal',
            name: 'A',
            localUpdatedAt: now,
          ),
          LocalClientsCompanion.insert(
            id: 'c2',
            organizationId: 'org1',
            kind: 'legal',
            name: 'B',
            localUpdatedAt: now,
          ),
          LocalClientsCompanion.insert(
            id: 'c3',
            organizationId: 'org1',
            kind: 'legal',
            name: 'C',
            localUpdatedAt: now,
          ),
        ]);
        b.insertAll(db.syncOutbox, [
          SyncOutboxCompanion.insert(
            operationId: 'op1',
            organizationId: 'org1',
            entityType: 'client',
            entityId: 'c1',
            operationType: 'update',
            payload: '{"name":"A2"}',
            occurredAt: now,
          ),
          SyncOutboxCompanion.insert(
            operationId: 'op2',
            organizationId: 'org1',
            entityType: 'client',
            entityId: 'c2',
            operationType: 'update',
            payload: '{"name":"B2"}',
            occurredAt: now,
          ),
          SyncOutboxCompanion.insert(
            operationId: 'op3',
            organizationId: 'org1',
            entityType: 'client',
            entityId: 'c3',
            operationType: 'update',
            payload: '{"name":"C2"}',
            occurredAt: now,
          ),
        ]);
      });

      when(() => api.push(any())).thenAnswer(
        (_) async => const [
          SyncOperationResult(
            operationId: 'op1',
            status: 'accepted',
            version: 2,
          ),
          SyncOperationResult(
            operationId: 'op2',
            status: 'conflict',
            errorCode: 'VERSION_CONFLICT',
          ),
          SyncOperationResult(
            operationId: 'op3',
            status: 'rejected',
            errorCode: 'INTERNAL',
          ),
        ],
      );

      await engine.pushPending();

      final c1 = await (db.select(
        db.localClients,
      )..where((t) => t.id.equals('c1'))).getSingle();
      expect(c1.version, 2);
      expect(c1.syncStatus, 'synced');

      final c2 = await (db.select(
        db.localClients,
      )..where((t) => t.id.equals('c2'))).getSingle();
      expect(c2.syncStatus, 'conflict');

      final remainingOutbox = await db.select(db.syncOutbox).get();
      expect(
        remainingOutbox.map((r) => r.operationId),
        ['op3'],
        reason:
            'op1/op2 saem da outbox; op3 (erro transitório) fica pra tentar de novo',
      );
    },
  );
}
