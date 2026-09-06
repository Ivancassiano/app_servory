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

/// Lotes de etiquetas — trabalho de escritório, **sempre online** (§9). No
/// app a *lista* vem do cache drift (os lotes sincronizam, só leitura); no
/// web vem do REST. Criar / reservar / exportar / marcar-perdido e a geração
/// do PDF são REST puro nas duas plataformas.
class LabelBatchRepository {
  LabelBatchRepository(this._ref);
  final Ref _ref;

  Dio get _dio => _ref.read(apiClientProvider).businessDio;
  String get _orgId => _ref.read(organizationIdProvider);
  AppDatabase get _db => _ref.read(appDatabaseProvider);

  final _webCtrl = StreamController<List<LocalQrBatch>>.broadcast();
  List<LocalQrBatch>? _webCache;

  void dispose() {
    if (kIsWeb) _webCtrl.close();
  }

  Stream<List<LocalQrBatch>> watchList() {
    if (kIsWeb) {
      scheduleMicrotask(() {
        // Só re-emite o cache se já buscou uma vez; senão deixa o provider
        // em loading até a 1ª resposta (evita piscar "nenhum lote").
        if (_webCache != null) _webCtrl.add(_webCache!);
        unawaited(refresh());
      });
      return _webCtrl.stream;
    }
    final q = _db.select(_db.localQrBatches)
      ..where((t) => t.deleted.equals(false))
      ..orderBy([
        (t) => OrderingTerm(
          expression: t.createdAt,
          mode: OrderingMode.desc,
        ),
      ]);
    return q.watch();
  }

  Future<void> refresh() async {
    if (kIsWeb) {
      try {
        final r = await restCall(
          () => _dio.get('/v1/qr-batches', queryParameters: {'size': 200}),
        );
        final raw =
            (r.data as Map<String, dynamic>)['batches'] as List? ?? const [];
        _webCache = raw
            .map(
              (e) => qrBatchFromApiJson(
                e as Map<String, dynamic>,
                organizationId: _orgId,
              ),
            )
            .toList();
        if (!_webCtrl.isClosed) _webCtrl.add(_webCache!);
      } on ApiException catch (e) {
        if (!_webCtrl.isClosed) _webCtrl.addError(e);
      }
      return;
    }
    await _ref.read(syncRunnerProvider.notifier).runSync();
  }

  Future<void> _warm(Map<String, dynamic> json) async {
    final batch = qrBatchFromApiJson(json, organizationId: _orgId);
    if (kIsWeb) {
      _webCache = [
        batch,
        ...(_webCache ?? const []).where((b) => b.id != batch.id),
      ];
      if (!_webCtrl.isClosed) _webCtrl.add(_webCache!);
    } else {
      await _db.into(_db.localQrBatches).insertOnConflictUpdate(batch);
    }
  }

  Future<LocalQrBatch> create({
    required String label,
    required int quantity,
  }) async {
    final r = await restCall(
      () => _dio.post(
        '/v1/qr-batches',
        data: {'label': label, 'quantity': quantity},
      ),
    );
    final body = r.data as Map<String, dynamic>;
    final batchJson = body['batch'] as Map<String, dynamic>;
    await _warm(batchJson);
    if (!kIsWeb) {
      await _upsertCodes(body['codes'] as List? ?? const []);
    }
    return qrBatchFromApiJson(batchJson, organizationId: _orgId);
  }

  Future<void> reserve(String id) => _action(id, 'reserve');
  Future<void> markLost(String id) => _action(id, 'mark-lost');

  /// `export` devolve `{batch, codes}` (reexportável, §9.3).
  Future<void> export(String id) async {
    final r = await restCall(
      () => _dio.post('/v1/qr-batches/$id/export'),
    );
    final body = r.data as Map<String, dynamic>;
    await _warm(body['batch'] as Map<String, dynamic>);
    if (!kIsWeb) await _upsertCodes(body['codes'] as List? ?? const []);
  }

  Future<void> _action(String id, String action) async {
    final r = await restCall(
      () => _dio.post('/v1/qr-batches/$id/$action'),
    );
    await _warm(r.data as Map<String, dynamic>);
  }

  Future<void> _upsertCodes(List<dynamic> codes) async {
    await _db.transaction(() async {
      for (final c in codes) {
        await _db.into(_db.localQrCodes).insertOnConflictUpdate(
              qrCodeFromApiJson(
                c as Map<String, dynamic>,
                organizationId: _orgId,
              ),
            );
      }
    });
  }

  /// Enfileira a folha de etiquetas, aguarda o job do worker e devolve os
  /// bytes do PDF já pronto (spec §10). `format` ∈ {full, compact, thermal};
  /// `companyId` e `templateId` são mutuamente exclusivos (ADR-0016/0017).
  Future<Uint8List> buildLabelSheetPdf(
    String batchId, {
    required String format,
    String? companyId,
    String? templateId,
  }) async {
    await restCall(
      () => _dio.post(
        '/v1/qr-batches/$batchId/pdf',
        data: {
          'format': format,
          'company_id': ?companyId,
          'template_id': ?templateId,
        },
      ),
    );

    // Polling do job assíncrono do worker.
    const maxWait = Duration(seconds: 45);
    final deadline = DateTime.now().add(maxWait);
    while (true) {
      await Future<void>.delayed(const Duration(milliseconds: 1500));
      final s = await restCall(
        () => _dio.get('/v1/qr-batches/$batchId/pdf'),
      );
      final status = (s.data as Map<String, dynamic>)['status'] as String?;
      if (status == 'done') break;
      if (status == 'failed') {
        final err =
            (s.data as Map<String, dynamic>)['last_error'] as String? ??
            'erro desconhecido';
        throw ApiException(
          code: 'PDF_FAILED',
          message: 'A geração do PDF falhou: $err',
        );
      }
      if (DateTime.now().isAfter(deadline)) {
        throw const ApiException(
          code: 'PDF_TIMEOUT',
          message: 'A geração do PDF está demorando. Tente de novo em instantes.',
        );
      }
    }

    final dl = await restCall(
      () => _dio.get('/v1/qr-batches/$batchId/pdf/download'),
    );
    final url = (dl.data as Map<String, dynamic>)['url'] as String;
    // URL assinada — sem o interceptor de auth.
    final bytes = await Dio().get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(bytes.data ?? const []);
  }
}

final labelBatchRepositoryProvider = Provider<LabelBatchRepository>((ref) {
  final repo = LabelBatchRepository(ref);
  ref.onDispose(repo.dispose);
  return repo;
});

final labelBatchListProvider = StreamProvider<List<LocalQrBatch>>(
  (ref) => ref.watch(labelBatchRepositoryProvider).watchList(),
);

/// Contagem de etiquetas em conflito (§9.3) — pendência visível na home.
/// Só faz sentido no app (o web não tem cache drift nem fila).
final qrConflictCountProvider = StreamProvider<int>((ref) {
  if (kIsWeb) return Stream.value(0);
  final db = ref.watch(appDatabaseProvider);
  final q = db.selectOnly(db.localQrCodes)
    ..addColumns([db.localQrCodes.id.count()])
    ..where(db.localQrCodes.syncStatus.equals('conflict'));
  return q.watch().map(
    (rows) => rows.first.read(db.localQrCodes.id.count()) ?? 0,
  );
});
