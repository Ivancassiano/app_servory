import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/task_repository.dart';

/// Fachada fina — a lógica online-first / offline vive no [TaskRepository].
class TaskEditController {
  TaskEditController(this._ref);
  final Ref _ref;

  Future<String> create({
    required String clientId,
    required TaskFields fields,
  }) => _ref
      .read(taskRepositoryProvider)
      .create(clientId: clientId, fields: fields);

  Future<void> update({
    required String taskId,
    int? baseVersion,
    required TaskFields fields,
  }) => _ref
      .read(taskRepositoryProvider)
      .update(id: taskId, baseVersion: baseVersion, fields: fields);

  Future<void> transition({
    required String taskId,
    int? baseVersion,
    required String action,
    String? generatedOrderId,
  }) => _ref.read(taskRepositoryProvider).transition(
    id: taskId,
    baseVersion: baseVersion,
    action: action,
    generatedOrderId: generatedOrderId,
  );

  Future<void> delete({required String taskId, int? baseVersion}) => _ref
      .read(taskRepositoryProvider)
      .delete(id: taskId, baseVersion: baseVersion);
}

final taskEditControllerProvider = Provider<TaskEditController>(
  (ref) => TaskEditController(ref),
);
