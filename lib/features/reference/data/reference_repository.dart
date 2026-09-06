import 'dart:async';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/network/rest.dart';
import '../../../core/providers.dart';
import '../../auth/application/session_controller.dart';
import '../../sync/application/sync_provider.dart';

/// Os três tipos de dado de referência REST-only usados pelo formulário de
/// ordem de serviço. `wire` é o valor persistido em `LocalReferenceData.kind`.
enum ReferenceKind {
  serviceOrderType('service_order_type'),
  company('company'),
  orgUser('org_user');

  const ReferenceKind(this.wire);
  final String wire;

  ({String path, String key}) get endpoint => switch (this) {
    ReferenceKind.serviceOrderType => (
      path: '/v1/service-order-types',
      key: 'service_order_types',
    ),
    ReferenceKind.company => (path: '/v1/companies', key: 'companies'),
    ReferenceKind.orgUser => (path: '/v1/users', key: 'users'),
  };
}

/// Item já normalizado para exibir num seletor.
class ReferenceItem {
  const ReferenceItem({
    required this.id,
    required this.label,
    this.subtitle = '',
  });

  final String id;
  final String label;
  final String subtitle;
}

/// Converte o JSON cru de cada endpoint no par (id, label, subtitle). O
/// endpoint de membros usa `user_id`; os demais, `id`.
ReferenceItem referenceItemFromApiJson(ReferenceKind kind, Map<String, dynamic> j) {
  switch (kind) {
    case ReferenceKind.orgUser:
      final email = (j['email'] as String? ?? '').trim();
      final name = (j['name'] as String? ?? '').trim();
      return ReferenceItem(
        id: j['user_id'] as String? ?? j['id'] as String? ?? '',
        label: name.isNotEmpty ? name : (email.isNotEmpty ? email : 'Sem nome'),
        subtitle: name.isNotEmpty ? email : '',
      );
    case ReferenceKind.serviceOrderType:
    case ReferenceKind.company:
      return ReferenceItem(
        id: j['id'] as String? ?? '',
        label: (j['name'] as String? ?? '').trim(),
      );
  }
}

/// Ver [EquipmentTypeRepository] para o racional. No app cacheia em drift
/// (offline), no web só memória.
abstract interface class ReferenceDataRepository {
  Stream<List<ReferenceItem>> watchList(ReferenceKind kind);

  /// Busca do servidor. Melhor esforço — as telas chamam ao abrir.
  Future<void> refresh(ReferenceKind kind);
}

final referenceDataRepositoryProvider = Provider<ReferenceDataRepository>((ref) {
  final orgId = ref.watch(organizationIdProvider);
  if (kIsWeb) {
    final repo = _RemoteReferenceDataRepository(
      ref.watch(apiClientProvider).businessDio,
    );
    ref.onDispose(repo.dispose);
    return repo;
  }
  return _LocalReferenceDataRepository(ref, orgId);
});

final referenceListProvider =
    StreamProvider.family<List<ReferenceItem>, ReferenceKind>(
      (ref, kind) => ref.watch(referenceDataRepositoryProvider).watchList(kind),
    );

// ---------------------------------------------------------------------------

class _LocalReferenceDataRepository implements ReferenceDataRepository {
  _LocalReferenceDataRepository(this._ref, this._orgId);
  final Ref _ref;
  final String _orgId;

  AppDatabase get _db => _ref.read(appDatabaseProvider);
  Dio get _dio => _ref.read(apiClientProvider).businessDio;

  @override
  Stream<List<ReferenceItem>> watchList(ReferenceKind kind) {
    final q = _db.select(_db.localReferenceData)
      ..where((t) => t.kind.equals(kind.wire))
      ..orderBy([(t) => OrderingTerm(expression: t.label)]);
    return q.watch().map(
      (rows) => rows
          .map(
            (r) => ReferenceItem(id: r.id, label: r.label, subtitle: r.subtitle),
          )
          .toList(),
    );
  }

  @override
  Future<void> refresh(ReferenceKind kind) async {
    final ep = kind.endpoint;
    final r = await restCall(() => _dio.get(ep.path));
    final raw = (r.data as Map<String, dynamic>)[ep.key] as List? ?? const [];
    final now = DateTime.now();
    final items = raw
        .map(
          (e) => referenceItemFromApiJson(kind, e as Map<String, dynamic>),
        )
        .where((i) => i.id.isNotEmpty)
        .toList();
    await _db.transaction(() async {
      await (_db.delete(
        _db.localReferenceData,
      )..where((t) => t.kind.equals(kind.wire))).go();
      for (final i in items) {
        await _db.into(_db.localReferenceData).insert(
              LocalReferenceDataCompanion.insert(
                kind: kind.wire,
                id: i.id,
                organizationId: _orgId,
                label: i.label,
                subtitle: Value(i.subtitle),
                cachedAt: now,
              ),
            );
      }
    });
  }
}

// ---------------------------------------------------------------------------

class _RemoteReferenceDataRepository implements ReferenceDataRepository {
  _RemoteReferenceDataRepository(this._dio);
  final Dio _dio;

  final _controllers =
      <ReferenceKind, StreamController<List<ReferenceItem>>>{};
  final _cache = <ReferenceKind, List<ReferenceItem>>{};

  StreamController<List<ReferenceItem>> _controller(ReferenceKind kind) =>
      _controllers.putIfAbsent(
        kind,
        () => StreamController<List<ReferenceItem>>.broadcast(),
      );

  void dispose() {
    for (final c in _controllers.values) {
      c.close();
    }
  }

  @override
  Stream<List<ReferenceItem>> watchList(ReferenceKind kind) {
    final ctrl = _controller(kind);
    scheduleMicrotask(() {
      if (_cache.containsKey(kind)) ctrl.add(_cache[kind]!);
      unawaited(refresh(kind));
    });
    return ctrl.stream;
  }

  @override
  Future<void> refresh(ReferenceKind kind) async {
    final ep = kind.endpoint;
    try {
      final r = await restCall(() => _dio.get(ep.path));
      final raw = (r.data as Map<String, dynamic>)[ep.key] as List? ?? const [];
      final items = raw
          .map((e) => referenceItemFromApiJson(kind, e as Map<String, dynamic>))
          .where((i) => i.id.isNotEmpty)
          .toList()
        ..sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
      _cache[kind] = items;
      if (!_controller(kind).isClosed) _controller(kind).add(items);
    } catch (e) {
      if (!_controller(kind).isClosed) _controller(kind).addError(e);
    }
  }
}
