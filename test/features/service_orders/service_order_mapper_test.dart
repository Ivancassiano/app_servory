import 'package:flutter_test/flutter_test.dart';
import 'package:servory/features/service_orders/data/service_order_mapper.dart';

void main() {
  test('serviceOrderFromApiJson: datas e campos snake_case', () {
    final o = serviceOrderFromApiJson(const {
      'id': 'so1',
      'client_id': 'c1',
      'status': 'in_progress',
      'reason': 'Forno',
      'work_performed': 'trocou',
      'started_at': '2026-03-04T05:06:07Z',
      'version': 2,
    }, organizationId: 'org1');
    expect(o.clientId, 'c1');
    expect(o.status, 'in_progress');
    expect(o.workPerformed, 'trocou');
    expect(o.startedAt, DateTime.utc(2026, 3, 4, 5, 6, 7));
    expect(o.version, 2);
  });

  test('servicePartCreateBody NÃO inclui service_order_id (vem no path)', () {
    final body = servicePartCreateBody(
      description: 'Peça',
      partNumber: '',
      quantity: '',
      unit: 'un',
      unitCost: '',
      unitPrice: '180,00',
      notes: '',
    );
    expect(body.containsKey('service_order_id'), isFalse);
    expect(body['quantity'], '1'); // vazio → 1
    expect(body['unit_cost'], isNull); // vazio → null
    expect(body['unit_price'], '180.00'); // vírgula BR → ponto
  });

  test('servicePartUpdateBody normaliza dinheiro', () {
    final body = servicePartUpdateBody(
      description: 'X',
      partNumber: '',
      quantity: '2',
      unit: '',
      unitCost: '12,50',
      unitPrice: '',
      notes: '',
    );
    expect(body['unit_cost'], '12.50');
    expect(body['unit_price'], isNull);
  });

  test('serviceOrderCreateBody omite location/equipment quando null', () {
    expect(
      serviceOrderCreateBody(clientId: 'c1', open: true, reason: 'r'),
      {'client_id': 'c1', 'open': true, 'reason': 'r'},
    );
  });

  test('serviceOrderCreateBody inclui refs e scheduled_for RFC3339', () {
    final body = serviceOrderCreateBody(
      clientId: 'c1',
      serviceOrderTypeId: 't1',
      companyId: 'co1',
      assignedUserId: 'u1',
      scheduledFor: DateTime.utc(2026, 9, 10, 14, 30),
      open: false,
      reason: '',
    );
    expect(body['service_order_type_id'], 't1');
    expect(body['company_id'], 'co1');
    expect(body['assigned_user_id'], 'u1');
    expect(body['scheduled_for'], '2026-09-10T14:30:00.000Z');
  });

  test('serviceOrderUpdateBody omite refs nulas (não dá pra limpar via REST)', () {
    final body = serviceOrderUpdateBody(
      reason: 'r',
      diagnosis: '',
      workPerformed: '',
      finalCondition: '',
      notes: '',
    );
    expect(body.containsKey('service_order_type_id'), isFalse);
    expect(body.containsKey('company_id'), isFalse);
    expect(body.containsKey('assigned_user_id'), isFalse);
    expect(body.containsKey('scheduled_for'), isFalse);
  });
}
