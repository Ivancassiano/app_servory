import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/paged_source.dart';
import '../../../core/db/app_database.dart';
import '../data/task_repository.dart';

export '../data/task_mapper.dart' show TaskTargetInput;
export '../data/task_repository.dart' show TaskFields, taskRepositoryProvider;

/// Delegam ao [taskRepositoryProvider] (drift no app, REST no web).
final taskListProvider = StreamProvider<List<LocalTask>>(
  (ref) => ref.watch(taskRepositoryProvider).watchList(),
);

final taskListPagingProvider = Provider<PagedSource?>(
  (ref) => pagingOf(ref.watch(taskRepositoryProvider)),
);

final taskByIdProvider = StreamProvider.family<LocalTask?, String>(
  (ref, id) => ref.watch(taskRepositoryProvider).watchById(id),
);

final taskTargetsProvider =
    StreamProvider.family<List<LocalTaskTarget>, String>(
      (ref, taskId) => ref.watch(taskRepositoryProvider).watchTargets(taskId),
    );

/// Tarefas de um cliente (derivado da lista completa).
final tasksByClientProvider = Provider.family<List<LocalTask>, String>((
  ref,
  clientId,
) {
  final all = ref.watch(taskListProvider).value ?? const [];
  return [
    for (final t in all)
      if (t.clientId == clientId) t,
  ];
});
