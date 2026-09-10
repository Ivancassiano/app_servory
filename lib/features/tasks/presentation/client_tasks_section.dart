import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/child_list_section.dart';
import '../application/tasks_provider.dart';
import 'task_list_screen.dart' show taskStatusLabels, taskWhenLabel;

/// Bloco "tarefas deste cliente" na tela do cliente — prévia + "Ver todas".
class ClientTasksSection extends ConsumerWidget {
  const ClientTasksSection({super.key, required this.clientId});

  final String clientId;

  static const _previewLimit = 4;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = [...ref.watch(tasksByClientProvider(clientId))]
      ..sort((a, b) {
        final ad = a.createdAt ?? DateTime(0);
        final bd = b.createdAt ?? DateTime(0);
        return bd.compareTo(ad);
      });
    final preview = tasks.take(_previewLimit).toList();
    final hasMore = tasks.length > _previewLimit;

    return ChildListSection(
      title: 'Tarefas',
      count: tasks.length,
      emptyMessage: 'Nenhuma tarefa para este cliente.',
      addLabel: 'Nova tarefa',
      onAdd: () => context.push('/tasks/new?clientId=$clientId'),
      seeAllLabel: hasMore ? 'Ver todas' : null,
      onSeeAll: hasMore
          ? () => context.push('/tasks?clientId=$clientId')
          : null,
      children: [
        for (final t in preview)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(
              t.description.isEmpty ? 'Tarefa sem descrição' : t.description,
            ),
            subtitle: Text(
              [
                taskStatusLabels[t.status] ?? t.status,
                if (taskWhenLabel(t).isNotEmpty) taskWhenLabel(t),
              ].join(' · '),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/tasks/${t.id}'),
          ),
      ],
    );
  }
}
