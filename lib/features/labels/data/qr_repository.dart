import 'dart:async';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/rest.dart';
import '../../../core/providers.dart';
import '../../auth/application/session_controller.dart';
import '../../sync/application/sync_provider.dart';
import 'qr_mapper.dart';

/// Leitura de etiquetas (Fatia 3a). No app lê do cache drift (populado pelo
/// sync); no web vai direto ao REST. `resolve` é sempre online — identificar
/// um código escaneado/digitado exige o servidor (GUIA-FLUTTER.md §9.1).
abstract interface class QrRepository {
  /// Etiqueta ativa (`status = assigned`) vinculada a este registro, ou
  /// `null` se não houver.
  Stream<LocalQrCode?> watchActive(QrTarget target);

  /// Identifica um código digitado ou escaneado. Sempre online.
  Future<QrResolved> resolve(String code);
}

final qrRepositoryProvider = Provider<QrRepository>((ref) {
  final orgId = ref.watch(organizationIdProvider);
  if (kIsWeb) {
    final repo = _RemoteQrRepository(
      ref.watch(apiClientProvider).businessDio,
      orgId,
    );
    ref.onDispose(repo.dispose);
    return repo;
  }
  return _LocalQrRepository(ref, orgId);
});

/// Etiqueta ativa de um registro, para a seção "Etiqueta" das telas de
/// detalhe. `family` chaveado pelo alvo.
final activeQrCodeProvider =
    StreamProvider.family<LocalQrCode?, QrTarget>(
      (ref, target) => ref.watch(qrRepositoryProvider).watchActive(target),
    );

// ---------------------------------------------------------------------------

class _LocalQrRepository implements QrRepository {
  _LocalQrRepository(this._ref, this._orgId);
  final Ref _ref;
  final String _orgId;

  AppDatabase get _db => _ref.read(appDatabaseProvider);
  Dio get _dio => _ref.read(apiClientProvider).businessDio;

  @override
  Stream<LocalQrCode?> watchActive(QrTarget target) {
    final q = _db.select(_db.localQrCodes)
      ..where(
        (t) =>
            t.status.equals('assigned') &
            t.deleted.equals(false) &
            _targetFilter(t, target),
      )
      ..orderBy([
        (t) => OrderingTerm(
          expression: t.assignedAt,
          mode: OrderingMode.desc,
        ),
      ])
      ..limit(1);
    return q.watch().map((rows) => rows.isEmpty ? null : rows.first);
  }

  Expression<bool> _targetFilter(LocalQrCodes t, QrTarget target) {
    if (target.clientId != null) return t.clientId.equals(target.clientId!);
    if (target.locationId != null) {
      return t.locationId.equals(target.locationId!);
    }
    return t.equipmentId.equals(target.equipmentId!);
  }

  @override
  Future<QrResolved> resolve(String code) async {
    final r = await restCall(
      () => _dio.get('/v1/qr-codes/resolve/${Uri.encodeComponent(code)}'),
    );
    return QrResolved.fromApiJson(
      r.data as Map<String, dynamic>,
      organizationId: _orgId,
    );
  }
}

// ---------------------------------------------------------------------------

class _RemoteQrRepository implements QrRepository {
  _RemoteQrRepository(this._dio, this._orgId);
  final Dio _dio;
  final String _orgId;

  final _controllers = <String, StreamController<LocalQrCode?>>{};
  final _cache = <String, LocalQrCode?>{};

  String _key(QrTarget t) =>
      '${t.clientId ?? ''}|${t.locationId ?? ''}|${t.equipmentId ?? ''}';

  void dispose() {
    for (final c in _controllers.values) {
      c.close();
    }
  }

  @override
  Stream<LocalQrCode?> watchActive(QrTarget target) {
    final key = _key(target);
    final ctrl = _controllers.putIfAbsent(
      key,
      () => StreamController<LocalQrCode?>.broadcast(),
    );
    scheduleMicrotask(() async {
      if (_cache.containsKey(key)) ctrl.add(_cache[key]);
      try {
        final r = await restCall(
          () => _dio.get('/v1/qr-codes', queryParameters: target.toQuery()),
        );
        final code = qrCodeFromApiJson(
          r.data as Map<String, dynamic>,
          organizationId: _orgId,
        );
        _cache[key] = code;
        if (!ctrl.isClosed) ctrl.add(code);
      } on ApiException catch (e) {
        if (e.code == 'NOT_FOUND') {
          _cache[key] = null;
          if (!ctrl.isClosed) ctrl.add(null);
        } else if (!ctrl.isClosed) {
          ctrl.addError(e);
        }
      }
    });
    return ctrl.stream;
  }

  @override
  Future<QrResolved> resolve(String code) async {
    final r = await restCall(
      () => _dio.get('/v1/qr-codes/resolve/${Uri.encodeComponent(code)}'),
    );
    return QrResolved.fromApiJson(
      r.data as Map<String, dynamic>,
      organizationId: _orgId,
    );
  }
}
