import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/data/remote_collection.dart';
import '../../../core/db/app_database.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/rest.dart';
import '../../../core/providers.dart';
import '../../auth/application/session_controller.dart';
import '../../sync/data/local_first_repository.dart';
import 'recommendation_mapper.dart';

/// Recomendações "para a próxima visita" (spec §7.6). Sincroniza como as peças
/// (entidade `service_order_recommendation`, GUIA-FLUTTER.md §8.4): no nativo é
/// local-first (funciona offline); no web é REST direto.
abstract interface class RecommendationRepository {
  Stream<List<LocalServiceOrderRecommendation>> watch(String orderId);
  Future<void> refresh(String orderId);

  Future<void> add(
    String orderId, {
    required String description,
    String priority = 'medium',
    String status = 'open',
    String notes = '',
    String? serviceOrderItemId,
  });

  Future<void> update(
    String orderId,
    String recId, {
    required int? version,
    required String description,
    required String priority,
    required String status,
    required String notes,
  });

  Future<void> delete(String orderId, String recId, {int? version});
}

final recommendationRepositoryProvider = Provider<RecommendationRepository>((
  ref,
) {
  if (kIsWeb) {
    final repo = _RemoteRecommendationRepository(ref);
    ref.onDispose(repo.dispose);
    return repo;
  }
  return _LocalFirstRecommendationRepository(ref);
});

final recommendationsProvider =
    StreamProvider.family<List<LocalServiceOrderRecommendation>, String>(
      (ref, orderId) =>
          ref.watch(recommendationRepositoryProvider).watch(orderId),
    );

// ---------------------------------------------------------------------------

class _LocalFirstRecommendationRepository extends LocalFirstRepositoryBase
    implements RecommendationRepository {
  _LocalFirstRecommendationRepository(super.ref);

  @override
  Stream<List<LocalServiceOrderRecommendation>> watch(String orderId) =>
      (db.select(db.localServiceOrderRecommendations)
            ..where(
              (t) =>
                  t.serviceOrderId.equals(orderId) & t.deleted.equals(false),
            )
            ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]))
          .watch();

  @override
  Future<void> refresh(String orderId) async {
    if (!online) return;
    try {
      final r = await restCall(
        () => dio.get('/v1/service-orders/$orderId/recommendations'),
      );
      final rows =
          (r.data as Map<String, dynamic>)['recommendations'] as List? ??
          const [];
      await db.transaction(() async {
        for (final e in rows) {
          await db
              .into(db.localServiceOrderRecommendations)
              .insertOnConflictUpdate(
                serviceRecommendationFromApiJson(
                  e as Map<String, dynamic>,
                  organizationId: orgId,
                ),
              );
        }
      });
    } on ApiException {
      // silencioso: a lista local segue valendo
    }
  }

  @override
  Future<void> add(
    String orderId, {
    required String description,
    String priority = 'medium',
    String status = 'open',
    String notes = '',
    String? serviceOrderItemId,
  }) async {
    final body = recommendationCreateBody(
      description: description,
      priority: priority,
      status: status,
      notes: notes,
      serviceOrderItemId: serviceOrderItemId,
    );
    if (online) {
      try {
        final r = await restCall(
          () => dio.post(
            '/v1/service-orders/$orderId/recommendations',
            data: body,
          ),
        );
        await db
            .into(db.localServiceOrderRecommendations)
            .insertOnConflictUpdate(
              serviceRecommendationFromApiJson(
                r.data as Map<String, dynamic>,
                organizationId: orgId,
              ),
            );
        return;
      } on ApiException catch (e) {
        if (!isOfflineError(e)) rethrow;
      }
    }
    final id = const Uuid().v4();
    await db.transaction(() async {
      await db
          .into(db.localServiceOrderRecommendations)
          .insert(
            LocalServiceOrderRecommendationsCompanion.insert(
              id: id,
              organizationId: orgId,
              serviceOrderId: orderId,
              serviceOrderItemId: Value(serviceOrderItemId),
              description: Value(description),
              priority: Value(priority),
              status: Value(status),
              notes: Value(notes),
              localUpdatedAt: DateTime.now(),
              syncStatus: const Value('pending'),
              lastSyncedAt: const Value(null),
            ),
          );
      await enqueue(
        entityType: 'service_order_recommendation',
        entityId: id,
        operationType: 'create',
        payload: {...body, 'service_order_id': orderId},
      );
    });
    unawaited(trySyncNow());
  }

  @override
  Future<void> update(
    String orderId,
    String recId, {
    required int? version,
    required String description,
    required String priority,
    required String status,
    required String notes,
  }) async {
    final body = recommendationUpdateBody(
      description: description,
      priority: priority,
      status: status,
      notes: notes,
    );
    if (online) {
      try {
        final r = await restCall(
          () => dio.patch(
            '/v1/service-orders/$orderId/recommendations/$recId',
            data: {...body, 'version': ?version},
          ),
        );
        await db
            .into(db.localServiceOrderRecommendations)
            .insertOnConflictUpdate(
              serviceRecommendationFromApiJson(
                r.data as Map<String, dynamic>,
                organizationId: orgId,
              ),
            );
        return;
      } on ApiException catch (e) {
        if (!isOfflineError(e)) rethrow;
      }
    }
    await db.transaction(() async {
      await (db.update(db.localServiceOrderRecommendations)
            ..where((t) => t.id.equals(recId)))
          .write(
            LocalServiceOrderRecommendationsCompanion(
              description: Value(description),
              priority: Value(priority),
              status: Value(status),
              notes: Value(notes),
              localUpdatedAt: Value(DateTime.now()),
              syncStatus: const Value('pending'),
            ),
          );
      await enqueue(
        entityType: 'service_order_recommendation',
        entityId: recId,
        operationType: 'update',
        payload: body,
        baseVersion: version,
      );
    });
    unawaited(trySyncNow());
  }

  @override
  Future<void> delete(String orderId, String recId, {int? version}) async {
    if (online) {
      try {
        await restCall(
          () => dio.delete(
            '/v1/service-orders/$orderId/recommendations/$recId',
          ),
        );
        await (db.delete(db.localServiceOrderRecommendations)
              ..where((t) => t.id.equals(recId)))
            .go();
        return;
      } on ApiException catch (e) {
        if (!isOfflineError(e)) rethrow;
      }
    }
    await db.transaction(() async {
      await (db.update(db.localServiceOrderRecommendations)
            ..where((t) => t.id.equals(recId)))
          .write(
            const LocalServiceOrderRecommendationsCompanion(
              deleted: Value(true),
              syncStatus: Value('pending'),
            ),
          );
      await enqueue(
        entityType: 'service_order_recommendation',
        entityId: recId,
        operationType: 'delete',
        payload: const {},
        baseVersion: version,
      );
    });
    unawaited(trySyncNow());
  }
}

// ---------------------------------------------------------------------------

/// Web: REST direto, sem cache local (a tela recarrega via `refresh`).
class _RemoteRecommendationRepository implements RecommendationRepository {
  _RemoteRecommendationRepository(this._ref);
  final Ref _ref;

  final _byOrder = <String, RemoteCollection<LocalServiceOrderRecommendation>>{};

  String get _orgId => _ref.read(organizationIdProvider);

  RemoteCollection<LocalServiceOrderRecommendation> _for(String orderId) =>
      _byOrder.putIfAbsent(
        orderId,
        () => RemoteCollection<LocalServiceOrderRecommendation>(
          dio: _ref.read(apiClientProvider).businessDio,
          listPath: '/v1/service-orders/$orderId/recommendations',
          listKey: 'recommendations',
          fromJson: (j) =>
              serviceRecommendationFromApiJson(j, organizationId: _orgId),
          idOf: (r) => r.id,
        ),
      );

  void dispose() {
    for (final c in _byOrder.values) {
      c.dispose();
    }
  }

  @override
  Stream<List<LocalServiceOrderRecommendation>> watch(String orderId) =>
      _for(orderId).watchList();

  @override
  Future<void> refresh(String orderId) => _for(orderId).refresh();

  @override
  Future<void> add(
    String orderId, {
    required String description,
    String priority = 'medium',
    String status = 'open',
    String notes = '',
    String? serviceOrderItemId,
  }) => _for(orderId).create(
    recommendationCreateBody(
      description: description,
      priority: priority,
      status: status,
      notes: notes,
      serviceOrderItemId: serviceOrderItemId,
    ),
  );

  @override
  Future<void> update(
    String orderId,
    String recId, {
    required int? version,
    required String description,
    required String priority,
    required String status,
    required String notes,
  }) => _for(orderId).update(recId, {
    ...recommendationUpdateBody(
      description: description,
      priority: priority,
      status: status,
      notes: notes,
    ),
    'version': ?version,
  });

  @override
  Future<void> delete(String orderId, String recId, {int? version}) =>
      _for(orderId).remove(recId);
}
