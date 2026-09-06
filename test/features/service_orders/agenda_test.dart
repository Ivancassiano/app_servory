import 'package:flutter_test/flutter_test.dart';
import 'package:servory/features/service_orders/application/agenda.dart';
import 'package:servory/features/service_orders/application/service_orders_provider.dart';
import 'package:servory/features/service_orders/data/service_order_mapper.dart';

ServiceOrderWithClient _order({
  required String id,
  required DateTime? scheduled,
  String status = 'open',
  String reason = '',
  String client = 'Cliente',
}) {
  final o = serviceOrderFromApiJson({
    'id': id,
    'client_id': 'c1',
    'status': status,
    'reason': reason,
    if (scheduled != null) 'scheduled_for': scheduled.toUtc().toIso8601String(),
  }, organizationId: 'org');
  return ServiceOrderWithClient(order: o, clientName: client);
}

void main() {
  final now = DateTime(2026, 9, 10, 14, 0); // qui

  group('buildAgenda', () {
    test('classifica em atrasada / hoje / próximos e ignora o resto', () {
      final items = buildAgenda([
        _order(id: 'atras', scheduled: DateTime(2026, 9, 8, 9, 0)),
        _order(id: 'hoje', scheduled: DateTime(2026, 9, 10, 16, 30)),
        _order(id: 'amanha', scheduled: DateTime(2026, 9, 11, 8, 0)),
        _order(id: 'longe', scheduled: DateTime(2026, 9, 30, 8, 0)),
        _order(id: 'sem-data', scheduled: null),
      ], now: now);

      expect(items.map((i) => i.order.id), ['atras', 'hoje', 'amanha']);
      expect(items[0].bucket, AgendaBucket.overdue);
      expect(items[1].bucket, AgendaBucket.today);
      expect(items[2].bucket, AgendaBucket.upcoming);
    });

    test('ignora ordens concluídas mesmo agendadas', () {
      final items = buildAgenda([
        _order(id: 'ok', scheduled: DateTime(2026, 9, 10, 9, 0), status: 'completed'),
      ], now: now);
      expect(items, isEmpty);
    });

    test('ordena por data/hora crescente', () {
      final items = buildAgenda([
        _order(id: 'b', scheduled: DateTime(2026, 9, 10, 15, 0)),
        _order(id: 'a', scheduled: DateTime(2026, 9, 10, 9, 0)),
        _order(id: 'c', scheduled: DateTime(2026, 9, 12, 8, 0)),
      ], now: now);
      expect(items.map((i) => i.order.id), ['a', 'b', 'c']);
    });
  });

  group('agendaDateLabel', () {
    test('relativos', () {
      expect(agendaDateLabel(DateTime(2026, 9, 10, 14, 30), now), 'Hoje 14:30');
      expect(agendaDateLabel(DateTime(2026, 9, 11, 9, 5), now), 'Amanhã 09:05');
      expect(agendaDateLabel(DateTime(2026, 9, 9, 8, 0), now), 'Ontem 08:00');
      expect(agendaDateLabel(DateTime(2026, 9, 7, 8, 0), now), '3 dias atrás');
    });

    test('dia da semana dentro de 7 dias, data depois', () {
      expect(agendaDateLabel(DateTime(2026, 9, 13, 10, 0), now), 'Dom 10:00');
      expect(agendaDateLabel(DateTime(2026, 9, 20, 10, 0), now), '20/09 10:00');
    });
  });
}
