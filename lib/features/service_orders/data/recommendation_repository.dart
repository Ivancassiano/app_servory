import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/remote_collection.dart';
import '../../../core/network/api_parse.dart';
import '../../../core/providers.dart';

/// `ServiceOrderRecommendation` do OpenAPI — lista "para a próxima visita".
/// **REST-only** (não entra no sync, GUIA-FLUTTER.md §8.4): editar exige
/// conexão e a ordem precisa estar num status editável.
class Recommendation {
  const Recommendation({
    required this.id,
    required this.description,
    required this.priority,
    required this.status,
    required this.notes,
    this.version,
  });

  final String id;
  final String description;
  final String priority; // low | medium | high
  final String status; // open | addressed | dismissed
  final String notes;
  final int? version;

  factory Recommendation.fromApiJson(Map<String, dynamic> j) => Recommendation(
    id: j['id'] as String,
    description: stringOr(j['description']),
    priority: stringOr(j['priority'], 'medium'),
    status: stringOr(j['status'], 'open'),
    notes: stringOr(j['notes']),
    version: j['version'] as int?,
  );
}

Map<String, dynamic> _body({
  required String description,
  required String priority,
  required String status,
  required String notes,
}) => {
  'description': description,
  'priority': priority,
  'status': status,
  'notes': notes,
};

class RecommendationRepository {
  RecommendationRepository(this._ref);
  final Ref _ref;

  final _byOrder = <String, RemoteCollection<Recommendation>>{};

  RemoteCollection<Recommendation> _for(String orderId) => _byOrder.putIfAbsent(
    orderId,
    () => RemoteCollection<Recommendation>(
      dio: _ref.read(apiClientProvider).businessDio,
      listPath: '/v1/service-orders/$orderId/recommendations',
      listKey: 'recommendations',
      fromJson: Recommendation.fromApiJson,
      idOf: (r) => r.id,
    ),
  );

  void dispose() {
    for (final c in _byOrder.values) {
      c.dispose();
    }
  }

  Stream<List<Recommendation>> watch(String orderId) =>
      _for(orderId).watchList();

  Future<void> refresh(String orderId) => _for(orderId).refresh();

  Future<void> add(
    String orderId, {
    required String description,
    String priority = 'medium',
    String status = 'open',
    String notes = '',
  }) => _for(orderId).create(
    _body(
      description: description,
      priority: priority,
      status: status,
      notes: notes,
    ),
  );

  Future<void> update(
    String orderId,
    String recId, {
    required int? version,
    required String description,
    required String priority,
    required String status,
    required String notes,
  }) => _for(orderId).update(recId, {
    ..._body(
      description: description,
      priority: priority,
      status: status,
      notes: notes,
    ),
    'version': ?version,
  });

  Future<void> delete(String orderId, String recId) =>
      _for(orderId).remove(recId);
}

final recommendationRepositoryProvider = Provider<RecommendationRepository>((
  ref,
) {
  final repo = RecommendationRepository(ref);
  ref.onDispose(repo.dispose);
  return repo;
});

final recommendationsProvider =
    StreamProvider.family<List<Recommendation>, String>(
      (ref, orderId) =>
          ref.watch(recommendationRepositoryProvider).watch(orderId),
    );
