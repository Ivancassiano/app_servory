import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servory/core/db/app_database.dart';
import 'package:servory/features/sync/application/pending_target.dart';

void main() {
  late AppDatabase db;
  final now = DateTime(2026, 9, 20);

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<SyncOutboxData> addOp({
    required String entityType,
    required String entityId,
    String operationType = 'update',
    String payload = '{}',
  }) async {
    await db
        .into(db.syncOutbox)
        .insert(
          SyncOutboxCompanion.insert(
            operationId: 'op-$entityId',
            organizationId: 'org1',
            entityType: entityType,
            entityId: entityId,
            operationType: operationType,
            payload: payload,
            occurredAt: now,
            lastError: const Value('INVALID_FIELD_VALUE'),
          ),
        );
    return (db.select(
      db.syncOutbox,
    )..where((t) => t.operationId.equals('op-$entityId'))).getSingle();
  }

  test('cliente: rota do cliente e nome como assunto', () async {
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
    final t = await resolvePendingTarget(
      db,
      await addOp(entityType: 'client', entityId: 'c1'),
    );
    expect(t?.route, '/clients/c1');
    expect(t?.subject, 'ClimaTech');
  });

  test(
    'valor de campo: leva ao ITEM e mostra campo e valor recusado',
    () async {
      await db
          .into(db.localItems)
          .insert(
            LocalItemsCompanion.insert(
              id: 'i1',
              organizationId: 'org1',
              clientId: const Value('c1'),
              name: 'Split sala',
              localUpdatedAt: now,
            ),
          );
      await db
          .into(db.localItemFieldDefs)
          .insert(
            LocalItemFieldDefsCompanion.insert(
              id: 'd1',
              organizationId: 'org1',
              label: 'Cor',
              fieldKey: 'cor',
              dataType: 'select',
              cachedAt: now,
            ),
          );
      await db
          .into(db.localItemFieldValues)
          .insert(
            LocalItemFieldValuesCompanion.insert(
              id: 'fv1',
              organizationId: 'org1',
              itemId: 'i1',
              fieldDefId: 'd1',
              valueText: const Value('Azul'),
              localUpdatedAt: now,
            ),
          );
      final t = await resolvePendingTarget(
        db,
        await addOp(
          entityType: 'item_field_value',
          entityId: 'fv1',
          payload: '{"value":"Azul"}',
        ),
      );
      expect(t?.route, '/items/i1');
      expect(t?.subject, 'Split sala · campo Cor: "Azul"');
    },
  );

  test('valor de campo sem linha local: cai no item_id do payload', () async {
    final t = await resolvePendingTarget(
      db,
      await addOp(
        entityType: 'item_field_value',
        entityId: 'fv-sumiu',
        operationType: 'create',
        payload: '{"item_id":"i9","field_def_id":"d9","value":"x"}',
      ),
    );
    expect(t?.route, '/items/i9');
    expect(t?.subject, isNull);
  });

  test('item da ordem: rota aninhada na ordem', () async {
    await db
        .into(db.localServiceOrderItems)
        .insert(
          LocalServiceOrderItemsCompanion.insert(
            id: 'soi1',
            organizationId: 'org1',
            serviceOrderId: 'so1',
            itemId: 'i1',
            localUpdatedAt: now,
          ),
        );
    final t = await resolvePendingTarget(
      db,
      await addOp(entityType: 'service_order_item', entityId: 'soi1'),
    );
    expect(t?.route, '/service-orders/so1/items/soi1');
  });

  test('entidade sem tela (qr_code): sem destino', () async {
    final t = await resolvePendingTarget(
      db,
      await addOp(entityType: 'qr_code', entityId: 'q1'),
    );
    expect(t, isNull);
  });
}
