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
import '../../sync/data/local_first_repository.dart';
import 'qr_mapper.dart';

/// Ação de etiqueta que não pode ser feita agora (regra offline da §9.1/§9.4).
/// A UI mostra [friendlyMessage] direto.
class QrActionException implements Exception {
  const QrActionException(this.friendlyMessage);
  final String friendlyMessage;

  static const unknownOffline = QrActionException(
    'Sem conexão para validar esta etiqueta. Offline só dá pra vincular uma '
    'etiqueta de um lote já reservado neste aparelho.',
  );
  static const replaceNeedsSpare = QrActionException(
    'Substituir offline exige uma etiqueta sobressalente já reservada neste '
    'aparelho.',
  );
}

/// Leitura + ações de etiqueta. No app é online-first (online → REST + aquece
/// o cache; offline → drift + outbox, respeitando a regra do inventário
/// local, §9.1); no web é REST puro. `resolve` é sempre online.
abstract interface class QrRepository {
  /// Etiqueta ativa (`status = assigned`) vinculada a este registro, ou
  /// `null`.
  Stream<LocalQrCode?> watchActive(QrTarget target);

  /// Identifica um código digitado ou escaneado. Sempre online.
  Future<QrResolved> resolve(String code);

  /// Gera uma etiqueta nova já vinculada a este registro
  /// (`POST /v1/qr-codes`, §8.5). Sempre online — o código público só o
  /// servidor gera (ADR-0019).
  Future<void> createBound(QrTarget target);

  /// Vincula uma etiqueta livre/reservada a um destino
  /// (`POST /v1/qr-codes/{id}/assign`).
  Future<void> assign({
    required String codeId,
    required QrTarget target,
    int? baseVersion,
  });

  /// Substitui a etiqueta ativa. Sem `newCodeId` o servidor gera uma nova —
  /// **não funciona offline** (§9.4).
  Future<void> replace({
    required String codeId,
    String? newCodeId,
    int? baseVersion,
  });

  /// Desativa a etiqueta ativa (`POST /v1/qr-codes/{id}/deactivate`).
  Future<void> deactivate({required String codeId, int? baseVersion});
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
  return _LocalQrRepository(ref);
});

/// Etiqueta ativa de um registro, para a seção "Etiqueta" das telas de
/// detalhe. `family` chaveado pelo alvo.
final activeQrCodeProvider = StreamProvider.family<LocalQrCode?, QrTarget>(
  (ref, target) => ref.watch(qrRepositoryProvider).watchActive(target),
);

// ---------------------------------------------------------------------------

class _LocalQrRepository extends LocalFirstRepositoryBase
    implements QrRepository {
  _LocalQrRepository(super.ref);

  @override
  Stream<LocalQrCode?> watchActive(QrTarget target) {
    final q = db.select(db.localQrCodes)
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

  Future<LocalQrCode?> _localCode(String id) =>
      (db.select(db.localQrCodes)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  @override
  Future<QrResolved> resolve(String code) async {
    final r = await restCall(
      () => dio.get('/v1/qr-codes/resolve/${Uri.encodeComponent(code)}'),
    );
    return QrResolved.fromApiJson(
      r.data as Map<String, dynamic>,
      organizationId: orgId,
    );
  }

  @override
  Future<void> createBound(QrTarget target) async {
    final r = await restCall(
      () => dio.post('/v1/qr-codes', data: target.toJson()),
    );
    await db.into(db.localQrCodes).insertOnConflictUpdate(
          qrCodeFromApiJson(
            r.data as Map<String, dynamic>,
            organizationId: orgId,
          ),
        );
  }

  @override
  Future<void> assign({
    required String codeId,
    required QrTarget target,
    int? baseVersion,
  }) async {
    final body = target.toJson();
    if (online) {
      try {
        final r = await restCall(
          () => dio.post('/v1/qr-codes/$codeId/assign', data: body),
        );
        await db.into(db.localQrCodes).insertOnConflictUpdate(
              qrCodeFromApiJson(
                r.data as Map<String, dynamic>,
                organizationId: orgId,
              ),
            );
        return;
      } on ApiException catch (e) {
        if (!isOfflineError(e)) rethrow;
      }
    }
    // Offline: só uma etiqueta já conhecida localmente (§9.1).
    if (await _localCode(codeId) == null) {
      throw QrActionException.unknownOffline;
    }
    await db.transaction(() async {
      await (db.update(db.localQrCodes)..where((t) => t.id.equals(codeId)))
          .write(
        LocalQrCodesCompanion(
          status: const Value('assigned'),
          clientId: Value(target.clientId),
          locationId: Value(target.locationId),
          equipmentId: Value(target.equipmentId),
          assignedAt: Value(DateTime.now()),
          localUpdatedAt: Value(DateTime.now()),
          syncStatus: const Value('pending'),
        ),
      );
      await enqueue(
        entityType: 'qr_code',
        entityId: codeId,
        operationType: 'assign',
        payload: body,
        baseVersion: baseVersion,
      );
    });
    unawaited(trySyncNow());
  }

  @override
  Future<void> replace({
    required String codeId,
    String? newCodeId,
    int? baseVersion,
  }) async {
    final body = {'new_code_id': ?newCodeId};
    if (online) {
      try {
        final r = await restCall(
          () => dio.post('/v1/qr-codes/$codeId/replace', data: body),
        );
        // A resposta é a etiqueta NOVA (status assigned); a antiga vira
        // 'replaced' e chega no próximo pull (§9.4).
        await db.into(db.localQrCodes).insertOnConflictUpdate(
              qrCodeFromApiJson(
                r.data as Map<String, dynamic>,
                organizationId: orgId,
              ),
            );
        unawaited(trySyncNow());
        return;
      } on ApiException catch (e) {
        if (!isOfflineError(e)) rethrow;
      }
    }
    if (newCodeId == null) throw QrActionException.replaceNeedsSpare;
    final old = await _localCode(codeId);
    final spare = await _localCode(newCodeId);
    if (spare == null) throw QrActionException.unknownOffline;
    await db.transaction(() async {
      await (db.update(db.localQrCodes)..where((t) => t.id.equals(codeId)))
          .write(
        LocalQrCodesCompanion(
          status: const Value('replaced'),
          localUpdatedAt: Value(DateTime.now()),
          syncStatus: const Value('pending'),
        ),
      );
      await (db.update(db.localQrCodes)..where((t) => t.id.equals(newCodeId)))
          .write(
        LocalQrCodesCompanion(
          status: const Value('assigned'),
          clientId: Value(old?.clientId),
          locationId: Value(old?.locationId),
          equipmentId: Value(old?.equipmentId),
          assignedAt: Value(DateTime.now()),
          localUpdatedAt: Value(DateTime.now()),
          syncStatus: const Value('pending'),
        ),
      );
      await enqueue(
        entityType: 'qr_code',
        entityId: codeId,
        operationType: 'replace',
        payload: body,
        baseVersion: baseVersion,
      );
    });
    unawaited(trySyncNow());
  }

  @override
  Future<void> deactivate({required String codeId, int? baseVersion}) async {
    if (online) {
      try {
        final r = await restCall(
          () => dio.post('/v1/qr-codes/$codeId/deactivate'),
        );
        await db.into(db.localQrCodes).insertOnConflictUpdate(
              qrCodeFromApiJson(
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
      await (db.update(db.localQrCodes)..where((t) => t.id.equals(codeId)))
          .write(
        LocalQrCodesCompanion(
          status: const Value('deactivated'),
          localUpdatedAt: Value(DateTime.now()),
          syncStatus: const Value('pending'),
        ),
      );
      await enqueue(
        entityType: 'qr_code',
        entityId: codeId,
        operationType: 'deactivate',
        payload: const {},
        baseVersion: baseVersion,
      );
    });
    unawaited(trySyncNow());
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

  Future<void> _refresh(QrTarget target) async {
    final key = _key(target);
    final ctrl = _controllers[key];
    if (ctrl == null || ctrl.isClosed) return;
    try {
      final r = await restCall(
        () => _dio.get('/v1/qr-codes', queryParameters: target.toQuery()),
      );
      final code = qrCodeFromApiJson(
        r.data as Map<String, dynamic>,
        organizationId: _orgId,
      );
      _cache[key] = code;
      ctrl.add(code);
    } on ApiException catch (e) {
      if (e.code == 'NOT_FOUND') {
        _cache[key] = null;
        ctrl.add(null);
      } else {
        ctrl.addError(e);
      }
    }
  }

  @override
  Stream<LocalQrCode?> watchActive(QrTarget target) {
    final key = _key(target);
    final ctrl = _controllers.putIfAbsent(
      key,
      () => StreamController<LocalQrCode?>.broadcast(),
    );
    scheduleMicrotask(() {
      if (_cache.containsKey(key)) ctrl.add(_cache[key]);
      unawaited(_refresh(target));
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

  @override
  Future<void> createBound(QrTarget target) async {
    await restCall(() => _dio.post('/v1/qr-codes', data: target.toJson()));
    await _refresh(target);
  }

  @override
  Future<void> assign({
    required String codeId,
    required QrTarget target,
    int? baseVersion,
  }) async {
    await restCall(
      () => _dio.post('/v1/qr-codes/$codeId/assign', data: target.toJson()),
    );
    await _refresh(target);
  }

  @override
  Future<void> replace({
    required String codeId,
    String? newCodeId,
    int? baseVersion,
  }) async {
    await restCall(
      () => _dio.post(
        '/v1/qr-codes/$codeId/replace',
        data: {'new_code_id': ?newCodeId},
      ),
    );
    // Não sabemos o alvo aqui; a tela recarrega via invalidate do provider.
    for (final t in _controllers.keys.toList()) {
      final parts = t.split('|');
      await _refresh(
        parts[0].isNotEmpty
            ? QrTarget.client(parts[0])
            : parts[1].isNotEmpty
            ? QrTarget.location(parts[1])
            : QrTarget.equipment(parts[2]),
      );
    }
  }

  @override
  Future<void> deactivate({required String codeId, int? baseVersion}) async {
    await restCall(() => _dio.post('/v1/qr-codes/$codeId/deactivate'));
    for (final t in _controllers.keys.toList()) {
      final parts = t.split('|');
      await _refresh(
        parts[0].isNotEmpty
            ? QrTarget.client(parts[0])
            : parts[1].isNotEmpty
            ? QrTarget.location(parts[1])
            : QrTarget.equipment(parts[2]),
      );
    }
  }
}
