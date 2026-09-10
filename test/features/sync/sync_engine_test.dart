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
      expect(remainingOutbox.single.attempts, 1);
      expect(remainingOutbox.single.lastError, 'INTERNAL');
    },
  );

  test('pull de item_field_value limpa órfão nunca sincronizado do mesmo campo',
      () async {
    final now = DateTime.now();
    await db.into(db.localItemFieldValues).insert(
          LocalItemFieldValuesCompanion.insert(
            id: 'device-fv',
            organizationId: 'org1',
            itemId: 'i1',
            fieldDefId: 'd1',
            valueNumber: const Value(2),
            localUpdatedAt: now,
            syncStatus: const Value('conflict'),
          ),
        );
    when(() => api.pull(cursor: 0, limit: any(named: 'limit'))).thenAnswer(
      (_) async => const SyncPullResult(
        entities: [
          SyncEntityChange(
            entityType: 'item_field_value',
            entityId: 'server-fv',
            deleted: false,
            data: {
              'id': 'server-fv',
              'item_id': 'i1',
              'field_def_id': 'd1',
              'value_text': null,
              'value_number': '2', // string do backend
              'value_datetime': null,
              'value_boolean': null,
              'version': 1,
            },
          ),
        ],
        nextCursor: 10,
      ),
    );
    when(() => api.pull(cursor: 10, limit: any(named: 'limit'))).thenAnswer(
      (_) async => const SyncPullResult(entities: [], nextCursor: 10),
    );

    await engine.pull();

    final rows = await db.select(db.localItemFieldValues).get();
    expect(rows.map((r) => r.id), ['server-fv']);
    expect(rows.single.valueNumber, 2.0);
  });

  test(
    'push: create de item_field_value em conflito apaga o órfão local',
    () async {
      final now = DateTime.now();
      await db.batch((b) {
        b.insert(
          db.localItemFieldValues,
          LocalItemFieldValuesCompanion.insert(
            id: 'device-fv',
            organizationId: 'org1',
            itemId: 'i1',
            fieldDefId: 'd1',
            valueNumber: const Value(2),
            localUpdatedAt: now,
            syncStatus: const Value('pending'),
          ),
        );
        b.insert(
          db.syncOutbox,
          SyncOutboxCompanion.insert(
            operationId: 'op-c',
            organizationId: 'org1',
            entityType: 'item_field_value',
            entityId: 'device-fv',
            operationType: 'create',
            payload: '{"item_id":"i1","field_def_id":"d1","value":2}',
            occurredAt: now,
          ),
        );
      });

      when(() => api.push(any())).thenAnswer(
        (_) async => const [
          SyncOperationResult(
            operationId: 'op-c',
            status: 'conflict',
            errorCode: 'VERSION_CONFLICT',
          ),
        ],
      );

      await engine.pushPending();

      expect(await db.select(db.syncOutbox).get(), isEmpty);
      expect(
        await db.select(db.localItemFieldValues).get(),
        isEmpty,
        reason: 'servidor já tinha o valor; o órfão local sai e o pull traz o bom',
      );
    },
  );

  test(
    'push: update com base_version nulo pega a version atual da linha local',
    () async {
      final now = DateTime.now();
      await db.batch((b) {
        b.insert(
          db.localClients,
          LocalClientsCompanion.insert(
            id: 'c1',
            organizationId: 'org1',
            kind: 'legal',
            name: 'C',
            localUpdatedAt: now,
            version: const Value(7), // create já sincronizou
            syncStatus: const Value('pending'),
          ),
        );
        b.insert(
          db.syncOutbox,
          SyncOutboxCompanion.insert(
            operationId: 'op-u',
            organizationId: 'org1',
            entityType: 'client',
            entityId: 'c1',
            operationType: 'update',
            payload: '{"name":"C2"}',
            occurredAt: now,
            // base_version NÃO informado (enfileirado quando version era null)
          ),
        );
      });

      List<SyncOperationRequest>? sent;
      when(() => api.push(any())).thenAnswer((inv) async {
        sent = inv.positionalArguments.first as List<SyncOperationRequest>;
        return const [
          SyncOperationResult(
            operationId: 'op-u',
            status: 'accepted',
            version: 8,
          ),
        ];
      });

      await engine.pushPending();

      expect(sent!.single.baseVersion, 7);
      expect(await db.select(db.syncOutbox).get(), isEmpty);
    },
  );

  test('discardOperation: update presa vira "synced" e sai da outbox', () async {
    final now = DateTime.now();
    await db.batch((b) {
      b.insert(
        db.localClients,
        LocalClientsCompanion.insert(
          id: 'c1',
          organizationId: 'org1',
          kind: 'legal',
          name: 'Editado offline',
          localUpdatedAt: now,
          syncStatus: const Value('pending'),
          syncError: const Value('VALIDATION_ERROR'),
        ),
      );
      b.insert(
        db.syncOutbox,
        SyncOutboxCompanion.insert(
          operationId: 'op-x',
          organizationId: 'org1',
          entityType: 'client',
          entityId: 'c1',
          operationType: 'update',
          payload: '{"name":"Editado offline"}',
          occurredAt: now,
        ),
      );
    });

    await engine.discardOperation('op-x');

    expect(await db.select(db.syncOutbox).get(), isEmpty);
    final c1 = await (db.select(
      db.localClients,
    )..where((t) => t.id.equals('c1'))).getSingle();
    expect(c1.syncStatus, 'synced');
    expect(c1.syncError, isNull);
  });

  test('discardOperation: create presa apaga a linha local', () async {
    final now = DateTime.now();
    await db.batch((b) {
      b.insert(
        db.localClients,
        LocalClientsCompanion.insert(
          id: 'c-new',
          organizationId: 'org1',
          kind: 'legal',
          name: 'Nunca subiu',
          localUpdatedAt: now,
          syncStatus: const Value('pending'),
        ),
      );
      b.insert(
        db.syncOutbox,
        SyncOutboxCompanion.insert(
          operationId: 'op-new',
          organizationId: 'org1',
          entityType: 'client',
          entityId: 'c-new',
          operationType: 'create',
          payload: '{"name":"Nunca subiu"}',
          occurredAt: now,
        ),
      );
    });

    await engine.discardOperation('op-new');

    expect(await db.select(db.syncOutbox).get(), isEmpty);
    expect(
      await (db.select(
        db.localClients,
      )..where((t) => t.id.equals('c-new'))).getSingleOrNull(),
      isNull,
    );
  });

  test(
    'push: item também grava de volta na tabela certa (não só client)',
    () async {
      final now = DateTime.now();
      await db.batch((b) {
        b.insertAll(db.localItems, [
          LocalItemsCompanion.insert(
            id: 'i1',
            organizationId: 'org1',
            clientId: 'c1',
            name: 'Filial',
            localUpdatedAt: now,
          ),
        ]);
        b.insertAll(db.syncOutbox, [
          SyncOutboxCompanion.insert(
            operationId: 'op-item',
            organizationId: 'org1',
            entityType: 'item',
            entityId: 'i1',
            operationType: 'update',
            payload: '{"name":"Filial 2"}',
            occurredAt: now,
          ),
        ]);
      });

      when(() => api.push(any())).thenAnswer(
        (_) async => const [
          SyncOperationResult(
            operationId: 'op-item',
            status: 'accepted',
            version: 2,
          ),
        ],
      );

      await engine.pushPending();

      final item = await (db.select(
        db.localItems,
      )..where((t) => t.id.equals('i1'))).getSingle();
      expect(item.version, 2);
      expect(item.syncStatus, 'synced');
      expect(await db.select(db.syncOutbox).get(), isEmpty);
    },
  );

  test('bootstrap também popula service_order e service_order_part', () async {
    for (final entityType in ['client', 'item']) {
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
    when(
      () => api.bootstrap(
        entityType: 'service_order_recommendation',
        page: any(named: 'page'),
      ),
    ).thenAnswer(
      (_) async => const SyncBootstrapPage(
        items: [
          {
            'id': 'r1',
            'service_order_id': 'so1',
            'service_order_item_id': 'it1',
            'description': 'Trocar correia',
            'priority': 'high',
            'status': 'open',
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

    final rec = await (db.select(
      db.localServiceOrderRecommendations,
    )..where((t) => t.id.equals('r1'))).getSingle();
    expect(rec.serviceOrderId, 'so1');
    expect(rec.serviceOrderItemId, 'it1');
    expect(rec.description, 'Trocar correia');
    expect(rec.syncStatus, 'synced');
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
