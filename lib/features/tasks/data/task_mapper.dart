import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../../core/network/api_parse.dart';

/// REST/sync ↔ `LocalTask`. A resposta (`GET` e `data` de sync) traz os campos
/// planos; o corpo de `POST/PATCH` é quase igual (sem `id`/`status`/timestamps).
LocalTask taskFromApiJson(
  Map<String, dynamic> j, {
  required String organizationId,
}) {
  final now = DateTime.now();
  return LocalTask(
    id: j['id'] as String,
    organizationId: organizationId,
    clientId: stringOr(j['client_id']),
    taskTypeId: j['task_type_id'] as String?,
    assignedUserId: j['assigned_user_id'] as String?,
    companyId: j['company_id'] as String?,
    description: stringOr(j['description']),
    notes: stringOr(j['notes']),
    status: stringOr(j['status'], 'open'),
    scheduledFor: parseApiDate(j['scheduled_for']),
    scheduledAllDay: (j['scheduled_all_day'] as bool?) ?? false,
    recurrenceRule: stringOr(j['recurrence_rule']),
    generatedOrderId: j['generated_order_id'] as String?,
    completedAt: parseApiDate(j['completed_at']),
    canceledAt: parseApiDate(j['canceled_at']),
    version: j['version'] as int?,
    createdAt: parseApiDate(j['created_at']),
    updatedAt: parseApiDate(j['updated_at']),
    localUpdatedAt: now,
    lastSyncedAt: now,
    syncStatus: 'synced',
    deleted: false,
  );
}

/// Alvos da tarefa vindos de `data['targets']` — devolve companions prontos
/// para reescrever `local_task_targets` daquela tarefa.
List<LocalTaskTargetsCompanion> taskTargetsFromApiJson(Map<String, dynamic> j) {
  final taskId = j['id'] as String;
  final raw = (j['targets'] as List?) ?? const [];
  final out = <LocalTaskTargetsCompanion>[];
  for (var i = 0; i < raw.length; i++) {
    final t = raw[i] as Map<String, dynamic>;
    out.add(
      LocalTaskTargetsCompanion.insert(
        id: '$taskId:$i',
        taskId: taskId,
        locationId: Value(t['location_id'] as String?),
        itemId: Value(t['item_id'] as String?),
        position: Value(i),
      ),
    );
  }
  return out;
}

/// Um alvo escolhido no formulário da tarefa.
class TaskTargetInput {
  const TaskTargetInput({this.locationId, this.itemId});
  final String? locationId;
  final String? itemId;

  Map<String, dynamic> toJson() => {
    'location_id': locationId,
    'item_id': itemId,
  };
}

Map<String, dynamic> _taskFields({
  required String? taskTypeId,
  required String? assignedUserId,
  required String? companyId,
  required String description,
  required String notes,
  required DateTime? scheduledFor,
  required bool scheduledAllDay,
  required List<TaskTargetInput> targets,
}) => {
  'task_type_id': taskTypeId,
  'assigned_user_id': assignedUserId,
  'company_id': companyId,
  'description': description,
  'notes': notes,
  'scheduled_for': scheduledFor?.toUtc().toIso8601String(),
  'scheduled_all_day': scheduledAllDay,
  'recurrence_rule': '',
  'targets': [for (final t in targets) t.toJson()],
};

/// `POST /v1/tasks` — `client_id` obrigatório.
Map<String, dynamic> taskCreateBody({
  required String clientId,
  String? taskTypeId,
  String? assignedUserId,
  String? companyId,
  required String description,
  String notes = '',
  DateTime? scheduledFor,
  bool scheduledAllDay = false,
  List<TaskTargetInput> targets = const [],
}) => {
  'client_id': clientId,
  ..._taskFields(
    taskTypeId: taskTypeId,
    assignedUserId: assignedUserId,
    companyId: companyId,
    description: description,
    notes: notes,
    scheduledFor: scheduledFor,
    scheduledAllDay: scheduledAllDay,
    targets: targets,
  ),
};

/// `PATCH /v1/tasks/{id}` — sem `client_id` (imutável).
Map<String, dynamic> taskUpdateBody({
  String? taskTypeId,
  String? assignedUserId,
  String? companyId,
  required String description,
  String notes = '',
  DateTime? scheduledFor,
  bool scheduledAllDay = false,
  List<TaskTargetInput> targets = const [],
}) => _taskFields(
  taskTypeId: taskTypeId,
  assignedUserId: assignedUserId,
  companyId: companyId,
  description: description,
  notes: notes,
  scheduledFor: scheduledFor,
  scheduledAllDay: scheduledAllDay,
  targets: targets,
);
