import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servory/core/db/app_database.dart';
import 'package:servory/features/service_orders/application/service_order_pdf.dart';
import 'package:servory/features/service_orders/application/service_order_report.dart';

/// PNG 1x1 transparente — só para exercitar o caminho de imagem no PDF.
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

  Future<LocalServiceOrder> insertOrder({
    String status = 'completed',
    String diagnosis = '',
  }) async {
    final now = DateTime.now();
    await db
        .into(db.localServiceOrders)
        .insert(
          LocalServiceOrdersCompanion.insert(
            id: 'so1',
            organizationId: 'org1',
            clientId: 'c1',
            localUpdatedAt: now,
            status: Value(status),
            reason: const Value('Ar-condicionado não gela'),
            diagnosis: Value(diagnosis),
            completedAt: Value(now),
          ),
        );
    return (db.select(
      db.localServiceOrders,
    )..where((t) => t.id.equals('so1'))).getSingle();
  }

  ServiceOrderReportData reportData(
    LocalServiceOrder order, {
    List<LocalServiceOrderPart> parts = const [],
    List<ReportPhoto> photos = const [],
    Uint8List? signature,
  }) {
    return ServiceOrderReportData(
      order: order,
      client: null,
      location: null,
      equipment: null,
      parts: parts,
      photos: photos,
      signaturePng: signature,
      generatedAt: DateTime(2026, 5, 9, 14, 30),
      technicianName: 'Técnico Teste',
      organizationName: 'ClimaTech Serviços',
      hasPendingUploads: false,
    );
  }

  test('gera um PDF válido com dados mínimos', () async {
    final order = await insertOrder(diagnosis: 'Gás R-410A baixo.');
    final bytes = await buildServiceOrderPdf(reportData(order));

    expect(bytes, isNotEmpty);
    expect(
      String.fromCharCodes(bytes.take(5)),
      '%PDF-',
      reason: 'deve ser um PDF de verdade, não bytes quaisquer',
    );
  });

  test('inclui peças, fotos e assinatura sem estourar', () async {
    final order = await insertOrder();
    await db
        .into(db.localServiceOrderParts)
        .insert(
          LocalServiceOrderPartsCompanion.insert(
            id: 'p1',
            organizationId: 'org1',
            serviceOrderId: 'so1',
            localUpdatedAt: DateTime.now(),
            description: const Value('Compressor'),
            quantity: const Value('2'),
            unit: const Value('un'),
            unitPrice: const Value('1250.50'),
          ),
        );
    final parts = await (db.select(
      db.localServiceOrderParts,
    )..where((t) => t.serviceOrderId.equals('so1'))).get();

    final bytes = await buildServiceOrderPdf(
      reportData(
        order,
        parts: parts,
        photos: [
          ReportPhoto(bytes: _pngPixel, kind: 'before', caption: 'Antes do reparo'),
          ReportPhoto(bytes: _pngPixel),
        ],
        signature: _pngPixel,
      ),
    );

    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(bytes.length, greaterThan(1000));
  });

  test('aguenta ordem sem nenhum texto/peça/anexo', () async {
    final order = await insertOrder(status: 'draft');
    final bytes = await buildServiceOrderPdf(reportData(order));
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });
}
