import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servory/core/db/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  test('grava e lê um cliente local', () async {
    final now = DateTime.now();
    await db
        .into(db.localClients)
        .insert(
          LocalClientsCompanion.insert(
            id: 'c1',
            organizationId: 'org1',
            kind: 'legal',
            name: 'ClimaTech',
            localUpdatedAt: now,
          ),
        );

    final rows = await db.select(db.localClients).get();
    expect(rows, hasLength(1));
    expect(rows.single.name, 'ClimaTech');
    expect(
      rows.single.internalNotes,
      isNull,
      reason: 'campo mascarável ausente = sem permissão, não vazio',
    );
  });

  test('grava e lê ordem de serviço e peça local', () async {
    final now = DateTime.now();
    await db
        .into(db.localServiceOrders)
        .insert(
          LocalServiceOrdersCompanion.insert(
            id: 'so1',
            organizationId: 'org1',
            clientId: 'c1',
            localUpdatedAt: now,
          ),
        );
    await db
        .into(db.localServiceOrderParts)
        .insert(
          LocalServiceOrderPartsCompanion.insert(
            id: 'p1',
            organizationId: 'org1',
            serviceOrderId: 'so1',
            localUpdatedAt: now,
          ),
        );

    final order = await (db.select(
      db.localServiceOrders,
    )..where((t) => t.id.equals('so1'))).getSingle();
    expect(order.status, 'draft');
    expect(order.clientId, 'c1');

    final part = await (db.select(
      db.localServiceOrderParts,
    )..where((t) => t.id.equals('p1'))).getSingle();
    expect(part.serviceOrderId, 'so1');
    expect(part.quantity, '1');
    expect(
      part.unitCost,
      isNull,
      reason: 'campo mascarável ausente = sem permissão, não vazio',
    );
  });

  test('outbox: grava e drena uma operação pendente', () async {
    await db
        .into(db.syncOutbox)
        .insert(
          SyncOutboxCompanion.insert(
            operationId: 'op1',
            organizationId: 'org1',
            entityType: 'client',
            entityId: 'c1',
            operationType: 'update',
            payload: '{"name":"Novo nome"}',
            occurredAt: DateTime.now(),
          ),
        );

    var pending = await db.select(db.syncOutbox).get();
    expect(pending, hasLength(1));

    await (db.delete(
      db.syncOutbox,
    )..where((t) => t.operationId.equals('op1'))).go();
    pending = await db.select(db.syncOutbox).get();
    expect(pending, isEmpty);
  });

  test('cursor de sync persiste por organização', () async {
    await db
        .into(db.localSyncState)
        .insertOnConflictUpdate(
          LocalSyncStateCompanion.insert(
            organizationId: 'org1',
            cursor: const Value.absent(),
          ),
        );
    await (db.update(db.localSyncState)
          ..where((t) => t.organizationId.equals('org1')))
        .write(const LocalSyncStateCompanion(cursor: Value(42)));

    final row = await (db.select(
      db.localSyncState,
    )..where((t) => t.organizationId.equals('org1'))).getSingle();
    expect(row.cursor, 42);
  });
}
