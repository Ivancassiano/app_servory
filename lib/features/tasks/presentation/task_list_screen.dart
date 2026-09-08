import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/app_database.dart';
import '../../../core/widgets/brand_app_bar.dart';
import '../../../core/widgets/searchable_list_view.dart';
import '../../clients/application/clients_provider.dart';
import '../application/tasks_provider.dart';

const taskStatusLabels = {
  'open': 'Aberta',
  'done': 'Concluída',
  'canceled': 'Cancelada',
};

String taskWhenLabel(LocalTask t) {
  final d = t.scheduledFor?.toLocal();
  if (d == null) return '';
  String two(int n) => n.toString().padLeft(2, '0');
  final date = '${two(d.day)}/${two(d.month)}/${d.year}';
  return t.scheduledAllDay ? date : '$date ${two(d.hour)}:${two(d.minute)}';
}

/// Lista de tarefas. Com `clientId` fica presa àquele cliente.
class TaskListScreen extends ConsumerWidget {
  const TaskListScreen({super.key, this.clientId});

  final String? clientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        extraFilter: clientId == null ? null : (t) => t.clientId == clientId,
        searchText: (t) =>
            [t.description, clients[t.clientId] ?? ''].join(' '),
        itemBuilder: (context, t) {
          final when = taskWhenLabel(t);
          final subtitle = [
            if (clientId == null && clients[t.clientId] != null)
              clients[t.clientId]!,
            taskStatusLabels[t.status] ?? t.status,
            if (when.isNotEmpty) when,
          ].join(' · ');
          return ListTile(
            title: Text(
              t.description.isEmpty ? 'Tarefa sem descrição' : t.description,
            ),
            subtitle: subtitle.isEmpty ? null : Text(subtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/tasks/${t.id}'),
          );
        },
      ),
    );
  }
}
