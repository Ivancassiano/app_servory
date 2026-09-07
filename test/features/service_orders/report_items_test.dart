import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servory/core/db/app_database.dart';
import 'package:servory/features/service_orders/application/report_items.dart';
import 'package:servory/features/service_orders/application/service_order_report.dart';

final _pngPixel = Uint8List.fromList(
  base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk'
    '+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
  ),
);

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<LocalServiceOrderItem> insertItemRow(
    String id, {
    required String itemId,
    int position = 0,
  }) async {
    await db
        .into(db.localServiceOrderItems)
        .insert(
          LocalServiceOrderItemsCompanion.insert(
            id: id,
            organizationId: 'org1',
            serviceOrderId: 'so1',
            itemId: itemId,
            localUpdatedAt: DateTime.now(),
            position: Value(position),
          ),
        );
    return (db.select(
      db.localServiceOrderItems,
    )..where((t) => t.id.equals(id))).getSingle();
  }

  Future<LocalServiceOrderPart> insertPart(
    String id, {
    String? serviceOrderItemId,
  }) async {
    await db
        .into(db.localServiceOrderParts)
        .insert(
          LocalServiceOrderPartsCompanion.insert(
            id: id,
            organizationId: 'org1',
            serviceOrderId: 'so1',
            localUpdatedAt: DateTime.now(),
            serviceOrderItemId: Value(serviceOrderItemId),
          ),
        );
    return (db.select(
      db.localServiceOrderParts,
    )..where((t) => t.id.equals(id))).getSingle();
  }

  test('particiona fotos em gerais e por item, na ordem de position', () async {
    final rowB = await insertItemRow('soi-b', itemId: 'item-b', position: 2);
    final rowA = await insertItemRow('soi-a', itemId: 'item-a', position: 1);

    final generalPart = await insertPart('p-geral');
    final itemPart = await insertPart('p-a', serviceOrderItemId: 'soi-a');

    final photos = [
      ReportPhoto(bytes: _pngPixel, caption: 'geral'),
      ReportPhoto(
        bytes: _pngPixel,
        caption: 'do item A',
        serviceOrderItemId: 'soi-a',
      ),
      ReportPhoto(
        bytes: _pngPixel,
        caption: 'do item B',
        serviceOrderItemId: 'soi-b',
      ),
    ];

    final split = partitionReport(
      allParts: [generalPart, itemPart],
      itemRows: [rowB, rowA],
      catalogById: const {},
      allPhotos: photos,
    );

    expect(split.generalParts.map((p) => p.id), ['p-geral']);
    expect(split.generalPhotos.map((p) => p.caption), ['geral']);

    // ordenado por position: A (1) antes de B (2)
    expect(split.items.map((i) => i.row.id), ['soi-a', 'soi-b']);
    expect(split.items.first.parts.map((p) => p.id), ['p-a']);
    expect(split.items.first.photos.map((p) => p.caption), ['do item A']);
    expect(split.items.last.parts, isEmpty);
    expect(split.items.last.photos.map((p) => p.caption), ['do item B']);
  });

  test('sem fotos: generalPhotos vazio, itens sem fotos', () async {
    final row = await insertItemRow('soi-a', itemId: 'item-a');
    final split = partitionReport(
      allParts: const [],
      itemRows: [row],
      catalogById: const {},
    );
    expect(split.generalPhotos, isEmpty);
    expect(split.items.single.photos, isEmpty);
  });
}
