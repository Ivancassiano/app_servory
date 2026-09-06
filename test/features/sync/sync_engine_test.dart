import 'package:drift/drift.dart' show Value;
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
    // Padrão: página vazia para qualquer entityType não estubado
    // explicitamente (ex.: qr_code/qr_batch). `when()` específico no teste
    // sobrepõe.
    when(
      () => api.bootstrap(
        entityType: any(named: 'entityType'),
        page: any(named: 'page'),
      ),
    ).thenAnswer(
      (_) async => const SyncBootstrapPage(
        items: [],
        total: 0,
        page: 1,
        size: 100,
        cursor: 0,
      ),
    );
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
    when(
      () => api.bootstrap(
        entityType: 'service_order',
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
        entityType: 'service_order_part',
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

  test(
    'push: location e equipment também gravam de volta na tabela certa (não só client)',
    () async {
      final now = DateTime.now();
      await db.batch((b) {
        b.insertAll(db.localLocations, [
          LocalLocationsCompanion.insert(
            id: 'l1',
            organizationId: 'org1',
            clientId: 'c1',
            name: 'Filial',
            localUpdatedAt: now,
          ),
        ]);
        b.insertAll(db.localEquipments, [
          LocalEquipmentsCompanion.insert(
            id: 'e1',
            organizationId: 'org1',
            locationId: 'l1',
            equipmentTypeId: 't1',
            name: 'Ar-condicionado',
            localUpdatedAt: now,
          ),
        ]);
        b.insertAll(db.syncOutbox, [
          SyncOutboxCompanion.insert(
            operationId: 'op-loc',
            organizationId: 'org1',
            entityType: 'location',
            entityId: 'l1',
            operationType: 'update',
            payload: '{"name":"Filial 2"}',
            occurredAt: now,
          ),
          SyncOutboxCompanion.insert(
            operationId: 'op-eq',
            organizationId: 'org1',
            entityType: 'equipment',
            entityId: 'e1',
            operationType: 'update',
            payload: '{"notes":"revisado"}',
            occurredAt: now,
          ),
        ]);
      });

      when(() => api.push(any())).thenAnswer(
        (_) async => const [
          SyncOperationResult(
            operationId: 'op-loc',
            status: 'accepted',
            version: 2,
          ),
          SyncOperationResult(
            operationId: 'op-eq',
            status: 'conflict',
            errorCode: 'VERSION_CONFLICT',
          ),
        ],
      );

      await engine.pushPending();

      final location = await (db.select(
        db.localLocations,
      )..where((t) => t.id.equals('l1'))).getSingle();
      expect(location.version, 2);
      expect(location.syncStatus, 'synced');

      final equipment = await (db.select(
        db.localEquipments,
      )..where((t) => t.id.equals('e1'))).getSingle();
      expect(equipment.syncStatus, 'conflict');
      expect(equipment.syncError, 'VERSION_CONFLICT');

      expect(await db.select(db.syncOutbox).get(), isEmpty);
    },
  );

  test('bootstrap também popula service_order e service_order_part', () async {
    for (final entityType in ['client', 'location', 'equipment']) {
      when(
        () => api.bootstrap(
          entityType: entityType,
          page: any(named: 'page'),
        ),
      ).thenAnswer(
        (_) async => const SyncBootstrapPage(
          items: [],
          total: 0,
          page: 1,
          size: 100,
          cursor: 7,
        ),
      );
    }
    when(
      () => api.bootstrap(
        entityType: 'service_order',
        page: any(named: 'page'),
      ),
    ).thenAnswer(
      (_) async => const SyncBootstrapPage(
        items: [
          {
            'id': 'so1',
            'client_id': 'c1',
            'status': 'open',
            'reason': 'Não gela',
            'version': 1,
          },
        ],
        total: 1,
        page: 1,
        size: 100,
        cursor: 7,
      ),
    );
    when(
      () => api.bootstrap(
        entityType: 'service_order_part',
        page: any(named: 'page'),
      ),
    ).thenAnswer(
      (_) async => const SyncBootstrapPage(
        items: [
          {
            'id': 'p1',
            'service_order_id': 'so1',
            'description': 'Filtro',
            'quantity': '2',
            'version': 1,
          },
        ],
        total: 1,
        page: 1,
        size: 100,
        cursor: 7,
      ),
    );

    await engine.bootstrap();

    final order = await (db.select(
      db.localServiceOrders,
    )..where((t) => t.id.equals('so1'))).getSingle();
    expect(order.clientId, 'c1');
    expect(order.status, 'open');
    expect(order.syncStatus, 'synced');

    final part = await (db.select(
      db.localServiceOrderParts,
    )..where((t) => t.id.equals('p1'))).getSingle();
    expect(part.serviceOrderId, 'so1');
    expect(part.description, 'Filtro');
    expect(part.quantity, '2');
  });

  test('push: ação nomeada (start) da ordem e create/update/delete de peça '
      'gravam na tabela certa', () async {
    final now = DateTime.now();
    await db.batch((b) {
      b.insertAll(db.localServiceOrders, [
        LocalServiceOrdersCompanion.insert(
          id: 'so1',
          organizationId: 'org1',
          clientId: 'c1',
          status: const Value('open'),
          localUpdatedAt: now,
        ),
      ]);
      b.insertAll(db.localServiceOrderParts, [
        LocalServiceOrderPartsCompanion.insert(
          id: 'p1',
          organizationId: 'org1',
          serviceOrderId: 'so1',
          localUpdatedAt: now,
        ),
        LocalServiceOrderPartsCompanion.insert(
          id: 'p2',
          organizationId: 'org1',
          serviceOrderId: 'so1',
          localUpdatedAt: now,
        ),
      ]);
      b.insertAll(db.syncOutbox, [
        SyncOutboxCompanion.insert(
          operationId: 'op-start',
          organizationId: 'org1',
          entityType: 'service_order',
          entityId: 'so1',
          operationType: 'start',
          payload: '{}',
          baseVersion: const Value(null),
          occurredAt: now,
        ),
        SyncOutboxCompanion.insert(
          operationId: 'op-part-update',
          organizationId: 'org1',
          entityType: 'service_order_part',
          entityId: 'p1',
          operationType: 'update',
          payload: '{"description":"Correia"}',
          occurredAt: now,
        ),
        SyncOutboxCompanion.insert(
          operationId: 'op-part-delete',
          organizationId: 'org1',
          entityType: 'service_order_part',
          entityId: 'p2',
          operationType: 'delete',
          payload: '{}',
          occurredAt: now,
        ),
      ]);
    });

    when(() => api.push(any())).thenAnswer(
      (_) async => const [
        SyncOperationResult(
          operationId: 'op-start',
          status: 'accepted',
          version: 2,
        ),
        SyncOperationResult(
          operationId: 'op-part-update',
          status: 'accepted',
          version: 2,
        ),
        SyncOperationResult(operationId: 'op-part-delete', status: 'accepted'),
      ],
    );

    await engine.pushPending();

    final order = await (db.select(
      db.localServiceOrders,
    )..where((t) => t.id.equals('so1'))).getSingle();
    expect(
      order.version,
      2,
      reason:
          'despacho por entityType cobre ação nomeada, não só create/update',
    );
    expect(order.syncStatus, 'synced');

    final part1 = await (db.select(
      db.localServiceOrderParts,
    )..where((t) => t.id.equals('p1'))).getSingle();
    expect(part1.version, 2);
    expect(part1.syncStatus, 'synced');

    expect(await db.select(db.syncOutbox).get(), isEmpty);
  });
}
