import 'dart:async';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/data/paged_source.dart';
import '../../../core/data/remote_collection.dart';
import '../../../core/db/app_database.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/rest.dart';
import '../../../core/providers.dart';
import '../../auth/application/session_controller.dart';
import '../../sync/data/local_first_repository.dart';
import 'task_mapper.dart';

/// Campos editáveis de uma tarefa (tudo menos `clientId`, que é imutável).
class TaskFields {
  const TaskFields({
    required this.description,
    this.notes = '',
    this.taskTypeId,
    this.assignedUserId,
    this.companyId,
    this.scheduledFor,
    this.scheduledAllDay = false,
    this.targets = const [],
  });

  final String description;
  final String notes;
  final String? taskTypeId;
  final String? assignedUserId;
  final String? companyId;
  final DateTime? scheduledFor;
  final bool scheduledAllDay;
  final List<TaskTargetInput> targets;
}

abstract interface class TaskRepository {
  Stream<List<LocalTask>> watchList({String? clientId});
  Stream<LocalTask?> watchById(String id);
  Stream<List<LocalTaskTarget>> watchTargets(String taskId);
  Future<void> refresh();

  Future<String> create({required String clientId, required TaskFields fields});
  Future<void> update({
    required String id,
    required int? baseVersion,
    required TaskFields fields,
  });

  /// `action` ∈ {complete, cancel, reopen}. `generatedOrderId` só vale em
  /// `complete`.
  Future<void> transition({
    required String id,
    required int? baseVersion,
    required String action,
    String? generatedOrderId,
  });

  Future<void> delete({required String id, required int? baseVersion});
}

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final orgId = ref.watch(organizationIdProvider);
  if (kIsWeb) {
    final repo = RemoteTaskRepository(ref.watch(apiClientProvider).businessDio, orgId);
    ref.onDispose(repo.dispose);
    return repo;
  }
  return LocalFirstTaskRepository(ref);
});

// ---------------------------------------------------------------------------

class LocalFirstTaskRepository extends LocalFirstRepositoryBase
    implements TaskRepository {
  LocalFirstTaskRepository(super.ref);

  @override
  Stream<List<LocalTask>> watchList({String? clientId}) {
    final q = db.select(db.localTasks)
      ..where((t) => t.deleted.equals(false))
      ..orderBy([
        (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
      ]);
    if (clientId != null) {
      q.where((t) => t.clientId.equals(clientId));
    }
    return q.watch();
  }

  @override
  Stream<LocalTask?> watchById(String id) =>
      (db.select(db.localTasks)..where((t) => t.id.equals(id)))
          .watchSingleOrNull();

  @override
  Stream<List<LocalTaskTarget>> watchTargets(String taskId) {
    final q = db.select(db.localTaskTargets)
      ..where((t) => t.taskId.equals(taskId))
      ..orderBy([(t) => OrderingTerm(expression: t.position)]);
    return q.watch();
  }

  @override
  Future<void> refresh() => runSync();

  Future<void> _writeTargets(String taskId, List<TaskTargetInput> targets) async {
    await (db.delete(db.localTaskTargets)
          ..where((t) => t.taskId.equals(taskId)))
        .go();
    for (var i = 0; i < targets.length; i++) {
      await db.into(db.localTaskTargets).insert(
            LocalTaskTargetsCompanion.insert(
              id: '$taskId:$i',
              taskId: taskId,
              locationId: Value(targets[i].locationId),
              itemId: Value(targets[i].itemId),
              position: Value(i),
            ),
          );
    }
  }

  Future<void> _cacheFromApi(Map<String, dynamic> data) async {
    // `.toCompanion(false)` mantém as colunas nulas (Value(null)) no upsert —
    // sem isso o `insertOnConflictUpdate` de um data class OMITE nulos e não
    // limpa, p.ex., `generated_order_id` ao reabrir.
    await db.into(db.localTasks).insertOnConflictUpdate(
          taskFromApiJson(data, organizationId: orgId).toCompanion(false),
        );
    final id = data['id'] as String;
    await (db.delete(db.localTaskTargets)..where((t) => t.taskId.equals(id)))
        .go();
    for (final c in taskTargetsFromApiJson(data)) {
      await db.into(db.localTaskTargets).insert(c);
    }
  }

  @override
  Future<String> create({
    required String clientId,
    required TaskFields fields,
  }) async {
    final body = taskCreateBody(
      clientId: clientId,
      taskTypeId: fields.taskTypeId,
      assignedUserId: fields.assignedUserId,
      companyId: fields.companyId,
      description: fields.description,
      notes: fields.notes,
      scheduledFor: fields.scheduledFor,
      scheduledAllDay: fields.scheduledAllDay,
      targets: fields.targets,
    );
    if (online) {
      try {
        final r = await restCall(() => dio.post('/v1/tasks', data: body));
        final data = r.data as Map<String, dynamic>;
        await _cacheFromApi(data);
        return data['id'] as String;
      } on ApiException catch (e) {
        if (!isOfflineError(e)) rethrow;
      }
    }
    final id = const Uuid().v4();
    final now = DateTime.now();
    await db.transaction(() async {
      await db.into(db.localTasks).insert(
            LocalTasksCompanion.insert(
              id: id,
              organizationId: orgId,
              clientId: clientId,
              taskTypeId: Value(fields.taskTypeId),
              assignedUserId: Value(fields.assignedUserId),
              companyId: Value(fields.companyId),
              description: Value(fields.description),
              notes: Value(fields.notes),
              status: const Value('open'),
              scheduledFor: Value(fields.scheduledFor),
              scheduledAllDay: Value(fields.scheduledAllDay),
              localUpdatedAt: now,
              syncStatus: const Value('pending'),
              lastSyncedAt: const Value(null),
            ),
          );
      await _writeTargets(id, fields.targets);
      await enqueue(
        entityType: 'task',
        entityId: id,
        operationType: 'create',
        payload: body,
      );
    });
    unawaited(trySyncNow());
    return id;
  }

  @override
  Future<void> update({
    required String id,
    required int? baseVersion,
    required TaskFields fields,
  }) async {
    final body = taskUpdateBody(
      taskTypeId: fields.taskTypeId,
      assignedUserId: fields.assignedUserId,
      companyId: fields.companyId,
      description: fields.description,
      notes: fields.notes,
      scheduledFor: fields.scheduledFor,
      scheduledAllDay: fields.scheduledAllDay,
      targets: fields.targets,
    );
    if (online) {
      try {
        final r = await restCall(
          () => dio.patch(
            '/v1/tasks/$id',
            data: {...body, 'version': ?baseVersion},
          ),
        );
        await _cacheFromApi(r.data as Map<String, dynamic>);
        return;
      } on ApiException catch (e) {
        if (!isOfflineError(e)) rethrow;
      }
    }
    final now = DateTime.now();
    await db.transaction(() async {
      await (db.update(db.localTasks)..where((t) => t.id.equals(id))).write(
        LocalTasksCompanion(
          taskTypeId: Value(fields.taskTypeId),
          assignedUserId: Value(fields.assignedUserId),
          companyId: Value(fields.companyId),
          description: Value(fields.description),
          notes: Value(fields.notes),
          scheduledFor: Value(fields.scheduledFor),
          scheduledAllDay: Value(fields.scheduledAllDay),
          localUpdatedAt: Value(now),
          syncStatus: const Value('pending'),
        ),
      );
      await _writeTargets(id, fields.targets);
      await enqueue(
        entityType: 'task',
        entityId: id,
        operationType: 'update',
        payload: body,
        baseVersion: baseVersion,
      );
    });
    unawaited(trySyncNow());
  }

  @override
  Future<void> transition({
    required String id,
    required int? baseVersion,
    required String action,
    String? generatedOrderId,
  }) async {
    final payload = <String, dynamic>{
      if (action == 'complete') 'generated_order_id': generatedOrderId,
    };
    if (online) {
      try {
        final r = await restCall(
          () => dio.post(
            '/v1/tasks/$id/$action',
            data: {...payload, 'version': ?baseVersion},
          ),
        );
        await _cacheFromApi(r.data as Map<String, dynamic>);
        return;
      } on ApiException catch (e) {
        if (!isOfflineError(e)) rethrow;
      }
    }
    final now = DateTime.now();
    final (newStatus, completedAt, canceledAt, orderId) = switch (action) {
      'complete' => (
        'done',
        Value(now),
        const Value<DateTime?>(null),
        Value(generatedOrderId),
      ),
      'cancel' => (
        'canceled',
        const Value<DateTime?>(null),
        Value(now),
        const Value<String?>.absent(),
      ),
      'reopen' => (
        'open',
        const Value<DateTime?>(null),
        const Value<DateTime?>(null),
        const Value<String?>(null),
      ),
      _ => throw ArgumentError('transição inválida: $action'),
    };
    await db.transaction(() async {
      await (db.update(db.localTasks)..where((t) => t.id.equals(id))).write(
        LocalTasksCompanion(
          status: Value(newStatus),
          completedAt: completedAt,
          canceledAt: canceledAt,
          generatedOrderId: orderId,
          localUpdatedAt: Value(now),
          syncStatus: const Value('pending'),
        ),
      );
      await enqueue(
        entityType: 'task',
        entityId: id,
        operationType: action,
        payload: payload,
        baseVersion: baseVersion,
      );
    });
    unawaited(trySyncNow());
  }

  @override
  Future<void> delete({required String id, required int? baseVersion}) async {
    if (online) {
      try {
        await restCall(() => dio.delete('/v1/tasks/$id'));
        await (db.update(db.localTasks)..where((t) => t.id.equals(id)))
            .write(const LocalTasksCompanion(deleted: Value(true)));
        return;
      } on ApiException catch (e) {
        if (!isOfflineError(e)) rethrow;
      }
    }
    await db.transaction(() async {
      await (db.update(db.localTasks)..where((t) => t.id.equals(id))).write(
        LocalTasksCompanion(
          deleted: const Value(true),
          localUpdatedAt: Value(DateTime.now()),
          syncStatus: const Value('pending'),
        ),
      );
      await enqueue(
        entityType: 'task',
        entityId: id,
        operationType: 'delete',
        payload: const {},
        baseVersion: baseVersion,
      );
    });
    unawaited(trySyncNow());
  }
}

// ---------------------------------------------------------------------------

class RemoteTaskRepository implements TaskRepository, PagedListRepository {
  RemoteTaskRepository(this._dio, String orgId)
    : _collection = RemoteCollection<LocalTask>(
        dio: _dio,
        listPath: '/v1/tasks',
        listKey: 'tasks',
        fromJson: (j) => taskFromApiJson(j, organizationId: orgId),
        idOf: (t) => t.id,
        pageSize: 50,
      );

  final Dio _dio;
  final RemoteCollection<LocalTask> _collection;

  @override
  PagedSource? get listPaging => _collection;

  void dispose() => _collection.dispose();

  @override
  Stream<List<LocalTask>> watchList({String? clientId}) => _collection
      .watchList()
      .map(
        (rows) => clientId == null
            ? rows
            : rows.where((t) => t.clientId == clientId).toList(),
      );

  @override
  Stream<LocalTask?> watchById(String id) => _collection.watchById(id);

  @override
  Stream<List<LocalTaskTarget>> watchTargets(String taskId) async* {
    final r = await restCall(() => _dio.get('/v1/tasks/$taskId'));
    final raw = ((r.data as Map<String, dynamic>)['targets'] as List?) ?? const [];
    yield [
      for (var i = 0; i < raw.length; i++)
        LocalTaskTarget(
          id: '$taskId:$i',
          taskId: taskId,
          locationId: (raw[i] as Map<String, dynamic>)['location_id'] as String?,
          itemId: (raw[i] as Map<String, dynamic>)['item_id'] as String?,
          position: i,
        ),
    ];
  }

  @override
  Future<void> refresh() => _collection.refresh();

  @override
  Future<String> create({
    required String clientId,
    required TaskFields fields,
  }) async {
    final t = await _collection.create(
      taskCreateBody(
        clientId: clientId,
        taskTypeId: fields.taskTypeId,
        assignedUserId: fields.assignedUserId,
        companyId: fields.companyId,
        description: fields.description,
        notes: fields.notes,
        scheduledFor: fields.scheduledFor,
        scheduledAllDay: fields.scheduledAllDay,
        targets: fields.targets,
      ),
    );
    return t.id;
  }

  @override
  Future<void> update({
    required String id,
    required int? baseVersion,
    required TaskFields fields,
  }) async {
    await _collection.update(id, {
      ...taskUpdateBody(
        taskTypeId: fields.taskTypeId,
        assignedUserId: fields.assignedUserId,
        companyId: fields.companyId,
        description: fields.description,
        notes: fields.notes,
        scheduledFor: fields.scheduledFor,
        scheduledAllDay: fields.scheduledAllDay,
        targets: fields.targets,
      ),
      'version': ?baseVersion,
    });
  }

  @override
  Future<void> transition({
    required String id,
    required int? baseVersion,
    required String action,
    String? generatedOrderId,
  }) async {
    await restCall(
      () => _dio.post(
        '/v1/tasks/$id/$action',
        data: {
          if (action == 'complete') 'generated_order_id': generatedOrderId,
          'version': ?baseVersion,
        },
      ),
    );
    await _collection.refresh();
  }

  @override
  Future<void> delete({required String id, required int? baseVersion}) async {
    await restCall(() => _dio.delete('/v1/tasks/$id'));
    await _collection.refresh();
  }
}
