import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servory/core/db/app_database.dart';
import 'package:servory/features/clients/application/clients_provider.dart';
import 'package:servory/features/tasks/application/tasks_provider.dart';
import 'package:servory/features/tasks/data/task_mapper.dart';
import 'package:servory/features/tasks/presentation/task_list_screen.dart';

LocalTask _task(
  String id, {
  required String status,
  DateTime? scheduledFor,
  bool allDay = false,
  String clientId = 'c1',
}) => taskFromApiJson({
  'id': id,
  'client_id': clientId,
  'description': 'Tarefa $id',
  'status': status,
  'scheduled_for': scheduledFor?.toIso8601String(),
  'scheduled_all_day': allDay,
}, organizationId: 'org');

void main() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final nextMonth = today.add(const Duration(days: 32));
  final lastWeek = DateTime(now.year, now.month, now.day, 9)
      .subtract(const Duration(days: 8));

  final tasks = [
    _task('aberta-hoje', status: 'open', scheduledFor: today, allDay: true),
    _task('aberta-atrasada', status: 'open', scheduledFor: lastWeek),
    _task('concluida', status: 'done', scheduledFor: nextMonth),
    _task('sem-agenda', status: 'open'),
  ];

  Widget host() => ProviderScope(
    overrides: [
      taskListProvider.overrideWith((ref) => Stream.value(tasks)),
      clientListProvider.overrideWith((ref) => Stream.value(const [])),
    ],
    child: const MaterialApp(home: TaskListScreen()),
  );

  testWidgets('mostra a data/hora da agenda e o ícone de "sem agenda"', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    String two(int n) => n.toString().padLeft(2, '0');
    final atrasadaLabel =
        '${two(lastWeek.day)}/${two(lastWeek.month)}/${lastWeek.year} 09:00';
    expect(find.text(atrasadaLabel), findsOneWidget);
    expect(find.byIcon(Icons.event_busy), findsOneWidget);
  });

  testWidgets('filtro rápido por status', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    expect(find.text('Tarefa aberta-hoje'), findsOneWidget);
    expect(find.text('Tarefa concluida'), findsOneWidget);

    await tester.tap(find.text('Concluídas'));
    await tester.pumpAndSettle();

    expect(find.text('Tarefa concluida'), findsOneWidget);
    expect(find.text('Tarefa aberta-hoje'), findsNothing);
    expect(find.text('Tarefa sem-agenda'), findsNothing);
  });

  testWidgets('filtro por data: Hoje', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Hoje'));
    await tester.pumpAndSettle();

    expect(find.text('Tarefa aberta-hoje'), findsOneWidget);
    expect(find.text('Tarefa concluida'), findsNothing);
    expect(find.text('Tarefa aberta-atrasada'), findsNothing);
    expect(find.text('Tarefa sem-agenda'), findsNothing);
  });

  testWidgets('filtro por data: Atrasadas (só abertas vencidas)', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Atrasadas'));
    await tester.pumpAndSettle();

    expect(find.text('Tarefa aberta-atrasada'), findsOneWidget);
    expect(find.text('Tarefa aberta-hoje'), findsNothing);
    expect(find.text('Tarefa concluida'), findsNothing);
  });

  testWidgets('filtro por data: Sem agenda', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // "Sem agenda" aparece como chip e como legenda da linha — o chip é o 1º
    await tester.tap(find.text('Sem agenda').first);
    await tester.pumpAndSettle();

    expect(find.text('Tarefa sem-agenda'), findsOneWidget);
    expect(find.text('Tarefa aberta-hoje'), findsNothing);
  });
}
