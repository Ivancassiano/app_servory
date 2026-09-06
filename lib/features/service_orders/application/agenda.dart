import '../../../core/db/app_database.dart';
import 'service_orders_provider.dart';

/// Agrupa as ordens agendadas em "atrasada / hoje / próximos dias" para o
/// painel da home. Lógica pura (sem Flutter) pra testar fácil.
enum AgendaBucket { overdue, today, upcoming }

class AgendaItem {
  const AgendaItem({
    required this.entry,
    required this.scheduledLocal,
    required this.bucket,
  });

  final ServiceOrderWithClient entry;
  final DateTime scheduledLocal;
  final AgendaBucket bucket;

  LocalServiceOrder get order => entry.order;
}

/// Ordens com `scheduled_for` definido, ainda não concluídas, que caem entre
/// "qualquer data passada" e `now + upcomingDays`. Ordenado por data/hora.
List<AgendaItem> buildAgenda(
  List<ServiceOrderWithClient> orders, {
  required DateTime now,
  int upcomingDays = 7,
}) {
  final today = DateTime(now.year, now.month, now.day);
  final horizon = today.add(Duration(days: upcomingDays + 1));
  final items = <AgendaItem>[];

  for (final e in orders) {
    final scheduled = e.order.scheduledFor;
    if (scheduled == null) continue;
    if (e.order.status == 'completed') continue;

    final local = scheduled.toLocal();
    final day = DateTime(local.year, local.month, local.day);

    final AgendaBucket bucket;
    if (day.isBefore(today)) {
      bucket = AgendaBucket.overdue;
    } else if (day.isAtSameMomentAs(today)) {
      bucket = AgendaBucket.today;
    } else if (day.isBefore(horizon)) {
      bucket = AgendaBucket.upcoming;
    } else {
      continue;
    }

    items.add(
      AgendaItem(entry: e, scheduledLocal: local, bucket: bucket),
    );
  }

  items.sort((a, b) => a.scheduledLocal.compareTo(b.scheduledLocal));
  return items;
}

const _weekdays = [
  'Seg',
  'Ter',
  'Qua',
  'Qui',
  'Sex',
  'Sáb',
  'Dom',
];

String _hhmm(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

/// Rótulo curto e relativo: "Hoje 14:30", "Amanhã 09:00", "Qua 08:00",
/// "3 dias atrás", "12/03 10:00".
String agendaDateLabel(DateTime local, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(local.year, local.month, local.day);
  final diff = day.difference(today).inDays;

  if (diff == 0) return 'Hoje ${_hhmm(local)}';
  if (diff == 1) return 'Amanhã ${_hhmm(local)}';
  if (diff == -1) return 'Ontem ${_hhmm(local)}';
  if (diff < 0) return '${-diff} dias atrás';
  if (diff < 7) return '${_weekdays[day.weekday - 1]} ${_hhmm(local)}';
  return '${local.day.toString().padLeft(2, '0')}/'
      '${local.month.toString().padLeft(2, '0')} ${_hhmm(local)}';
}
