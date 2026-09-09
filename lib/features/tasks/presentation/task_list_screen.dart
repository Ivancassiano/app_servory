import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/app_database.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/brand_app_bar.dart';
import '../../../core/widgets/searchable_list_view.dart';
import '../../clients/application/clients_provider.dart';
import '../application/tasks_provider.dart';

const taskStatusLabels = {
  'open': 'Aberta',
  'done': 'Concluída',
  'canceled': 'Cancelada',
};

/// Rótulos do filtro rápido (chave = status, ou `null` p/ "Todas").
const _statusFilters = <String?, String>{
  null: 'Todas',
  'open': 'Abertas',
  'done': 'Concluídas',
  'canceled': 'Canceladas',
};

String taskWhenLabel(LocalTask t) {
  final d = t.scheduledFor?.toLocal();
  if (d == null) return '';
  String two(int n) => n.toString().padLeft(2, '0');
  final date = '${two(d.day)}/${two(d.month)}/${d.year}';
  return t.scheduledAllDay ? date : '$date ${two(d.hour)}:${two(d.minute)}';
}

/// Presets do filtro por data da agenda.
enum _DateFilter { any, overdue, today, week, none, custom }

const _dateFilterLabels = {
  _DateFilter.any: 'Qualquer data',
  _DateFilter.overdue: 'Atrasadas',
  _DateFilter.today: 'Hoje',
  _DateFilter.week: 'Esta semana',
  _DateFilter.none: 'Sem agenda',
};

DateTime _dayStart(DateTime d) => DateTime(d.year, d.month, d.day);

/// Lista de tarefas. Com `clientId` fica presa àquele cliente.
class TaskListScreen extends ConsumerStatefulWidget {
  const TaskListScreen({super.key, this.clientId});

  final String? clientId;

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen> {
  String? _status;
  _DateFilter _dateFilter = _DateFilter.any;
  DateTimeRange? _customRange;

  bool _matchesDate(LocalTask t) {
    if (_dateFilter == _DateFilter.any) return true;
    final d = t.scheduledFor?.toLocal();
    if (_dateFilter == _DateFilter.none) return d == null;
    if (d == null) return false;

    final now = DateTime.now();
    final today = _dayStart(now);
    switch (_dateFilter) {
      case _DateFilter.overdue:
        final late = t.scheduledAllDay
            ? _dayStart(d).isBefore(today)
            : d.isBefore(now);
        return late && t.status == 'open';
      case _DateFilter.today:
        return _dayStart(d) == today;
      case _DateFilter.week:
        final weekStart = today.subtract(Duration(days: today.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 7));
        return !d.isBefore(weekStart) && d.isBefore(weekEnd);
      case _DateFilter.custom:
        final r = _customRange;
        if (r == null) return true;
        final day = _dayStart(d);
        return !day.isBefore(_dayStart(r.start)) &&
            !day.isAfter(_dayStart(r.end));
      case _DateFilter.any:
      case _DateFilter.none:
        return true;
    }
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 5),
      initialDateRange: _customRange,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _customRange = picked;
      _dateFilter = _DateFilter.custom;
    });
  }

  String _customChipLabel() {
    final r = _customRange;
    if (r == null) return 'Período…';
    String d(DateTime x) =>
        '${x.day.toString().padLeft(2, '0')}/${x.month.toString().padLeft(2, '0')}';
    return _dayStart(r.start) == _dayStart(r.end)
        ? d(r.start)
        : '${d(r.start)}–${d(r.end)}';
  }

  @override
  Widget build(BuildContext context) {
    final clientId = widget.clientId;
    final async = ref.watch(taskListProvider);
    final clients = {
      for (final c in ref.watch(clientListProvider).value ?? const [])
        c.id: c.name,
    };
    final scopeName = clientId == null ? null : clients[clientId];
    final newQuery = clientId == null ? '' : '?clientId=$clientId';

    return Scaffold(
      appBar: brandAppBar(
        title: 'Tarefas',
        subtitle: scopeName,
        leading: clientId == null ? null : const BackButton(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/tasks/new$newQuery'),
        icon: const Icon(Icons.add),
        label: const Text('Nova tarefa'),
      ),
      body: SearchableListView<LocalTask>(
        async: async,
        onRefresh: () => ref.read(taskRepositoryProvider).refresh(),
        hintText: 'Buscar por descrição ou cliente',
        emptyMessage: 'Nenhuma tarefa.',
        extraFilter: (t) =>
            (clientId == null || t.clientId == clientId) &&
            (_status == null || t.status == _status) &&
            _matchesDate(t),
        filterBar: _FilterBar(
          status: _status,
          onStatus: (s) => setState(() => _status = s),
          dateFilter: _dateFilter,
          customLabel: _customChipLabel(),
          onDate: (f) => setState(() {
            _dateFilter = f;
            if (f != _DateFilter.custom) _customRange = null;
          }),
          onPickRange: _pickRange,
        ),
        searchText: (t) =>
            [t.description, clients[t.clientId] ?? ''].join(' '),
        itemBuilder: (context, t) {
          final when = taskWhenLabel(t);
          final overdue =
              t.status == 'open' &&
              t.scheduledFor != null &&
              (t.scheduledAllDay
                  ? _dayStart(t.scheduledFor!.toLocal())
                        .isBefore(_dayStart(DateTime.now()))
                  : t.scheduledFor!.toLocal().isBefore(DateTime.now()));
          final top = [
            if (clientId == null && clients[t.clientId] != null)
              clients[t.clientId]!,
            taskStatusLabels[t.status] ?? t.status,
          ].join(' · ');
          return ListTile(
            isThreeLine: top.isNotEmpty,
            title: Text(
              t.description.isEmpty ? 'Tarefa sem descrição' : t.description,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (top.isNotEmpty) Text(top),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      when.isEmpty ? Icons.event_busy : Icons.event,
                      size: 13,
                      color: overdue ? BrandColor.errorBar : null,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      when.isEmpty ? 'Sem agenda' : when,
                      style: TextStyle(
                        color: overdue ? BrandColor.errorBar : null,
                        fontWeight: overdue ? FontWeight.w600 : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/tasks/${t.id}'),
          );
        },
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.status,
    required this.onStatus,
    required this.dateFilter,
    required this.customLabel,
    required this.onDate,
    required this.onPickRange,
  });

  final String? status;
  final ValueChanged<String?> onStatus;
  final _DateFilter dateFilter;
  final String customLabel;
  final ValueChanged<_DateFilter> onDate;
  final VoidCallback onPickRange;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ChipRow(
          children: [
            for (final e in _statusFilters.entries)
              _Chip(
                label: e.value,
                selected: status == e.key,
                onTap: () => onStatus(e.key),
              ),
          ],
        ),
        const SizedBox(height: 6),
        _ChipRow(
          children: [
            for (final e in _dateFilterLabels.entries)
              _Chip(
                label: e.value,
                selected: dateFilter == e.key,
                onTap: () => onDate(e.key),
              ),
            _Chip(
              label: customLabel,
              selected: dateFilter == _DateFilter.custom,
              onTap: onPickRange,
              icon: Icons.date_range,
            ),
          ],
        ),
      ],
    );
  }
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          for (final (i, c) in children.indexed) ...[
            if (i > 0) const SizedBox(width: 8),
            c,
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? BrandColor.ink : BrandColor.surface,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? BrandColor.ink : BrandColor.border,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 13,
                  color: selected ? Colors.white : BrandColor.ink,
                ),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'IBM Plex Mono',
                  fontSize: 11,
                  color: selected ? Colors.white : BrandColor.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
