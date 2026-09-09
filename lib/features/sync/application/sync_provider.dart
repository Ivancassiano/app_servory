import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/providers.dart';
import '../../attachments/application/drain_uploads.dart';
import '../../attachments/application/service_order_attachments_provider.dart';
import '../../auth/application/session_controller.dart';
import '../data/sync_api.dart';
import 'sync_engine.dart';

/// Banco local da organização ativa — só existe autenticado; recriado a
/// cada troca de sessão (`ref.watch` do estado de sessão) e fechado quando
/// deixa de ser usado.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final session = ref.watch(sessionControllerProvider);
  if (session is! SessionAuthenticated) {
    throw StateError('appDatabaseProvider lido sem sessão autenticada');
  }
  final db = AppDatabase.forOrganization(session.organizationId);
  ref.onDispose(db.close);
  return db;
});

final syncApiProvider = Provider<SyncApi>(
  (ref) => SyncApi(ref.watch(apiClientProvider).businessDio),
);

final syncEngineProvider = Provider<SyncEngine>((ref) {
  final session = ref.watch(sessionControllerProvider);
  if (session is! SessionAuthenticated) {
    throw StateError('syncEngineProvider lido sem sessão autenticada');
  }
  return SyncEngine(
    api: ref.watch(syncApiProvider),
    db: ref.watch(appDatabaseProvider),
    organizationId: session.organizationId,
  );
});

/// Estado de sincronização que a UI observa: a fase atual (`phase`) e quando
/// foi o último sync bem-sucedido (`lastSuccessAt`, pra faixa de status
/// mostrar "atualizado há X min"). Os getters `isLoading`/`hasError` deixam o
/// código que só olhava a `AsyncValue` continuar funcionando.
class SyncStatus {
  const SyncStatus({
    this.phase = const AsyncValue<void>.data(null),
    this.lastSuccessAt,
  });

  final AsyncValue<void> phase;
  final DateTime? lastSuccessAt;

  bool get isLoading => phase.isLoading;
  bool get hasError => phase.hasError;

  SyncStatus _copy({AsyncValue<void>? phase, DateTime? lastSuccessAt}) =>
      SyncStatus(
        phase: phase ?? this.phase,
        lastSuccessAt: lastSuccessAt ?? this.lastSuccessAt,
      );
}

/// "Está sincronizando agora?" — a UI usa pra mostrar spinner/erro.
class SyncRunner extends Notifier<SyncStatus> {
  @override
  SyncStatus build() => const SyncStatus();

  /// Roda o `bootstrap` só se o banco local desta organização ainda
  /// estiver vazio (1ª sincronização do dispositivo, GUIA-FLUTTER.md §8.2).
  Future<void> bootstrapIfNeeded() async {
    final db = ref.read(appDatabaseProvider);
    final existing = await (db.select(
      db.localClients,
    )..limit(1)).getSingleOrNull();
    if (existing != null) return;
    await runSync(bootstrap: true);
  }

  Future<void> runSync({bool bootstrap = false}) async {
    state = state._copy(phase: const AsyncValue<void>.loading());
    final engine = ref.read(syncEngineProvider);
    final result = await AsyncValue.guard(() async {
      if (bootstrap) {
        await engine.bootstrap();
        await engine.pushPending();
        return;
      }
      // Drena a outbox local ANTES de puxar: uma ação recente (ex.: `start`
      // seguido de `complete` em sequência rápida) gera, no próprio push
      // anterior, um evento de outbox no servidor que ainda não foi puxado.
      // Puxar antes de empurrar aplicaria esse estado "velho" por cima de
      // uma escrita local otimista mais nova que ainda está na outbox,
      // sobrescrevendo-a sem o push (que só atualiza `version`) corrigir —
      // achado ao testar start→complete em sequência na mesma ordem.
      await engine.pushPending();
      await engine.pull();
    });
    state = state._copy(
      phase: result,
      lastSuccessAt: result.hasError ? state.lastSuccessAt : DateTime.now(),
    );
  }

  /// "Atualizar tudo": sync (push + pull), **envia as fotos/assinatura ainda
  /// na fila** (senão a barra fica presa em "1 alteração não enviada"),
  /// recarrega o que é REST puro e fica FORA do protocolo de sync (fotos e
  /// assinatura, cuja URL de download é assinada e temporária, §26.4) e limpa
  /// o cache de imagens. É o botão da faixa de status em todas as telas.
  Future<void> refreshEverything() async {
    await runSync();
    await drainUploads(ref);
    ref.invalidate(entityPhotosProvider);
    ref.invalidate(orderSignatureProvider);
    PaintingBinding.instance.imageCache
      ..clear()
      ..clearLiveImages();
  }
}

final syncRunnerProvider = NotifierProvider<SyncRunner, SyncStatus>(
  SyncRunner.new,
);

/// Total de alterações locais aguardando envio ao servidor: operações na
/// outbox (create/update/ações nomeadas) + anexos (foto/assinatura) na fila
/// de upload. `0` = tudo o que foi feito neste aparelho já está no servidor
/// (seguro atualizar o app). Alimenta o aviso da barra de status.
final pendingSyncCountStreamProvider = StreamProvider<int>((ref) {
  if (kIsWeb) return Stream.value(0);
  final AppDatabase db;
  try {
    db = ref.watch(appDatabaseProvider);
  } catch (_) {
    return Stream.value(0); // sem sessão autenticada — nada local para contar
  }
  return db
      .customSelect(
        'SELECT '
        '(SELECT COUNT(*) FROM sync_outbox) + '
        '(SELECT COUNT(*) FROM upload_queue) AS n',
        readsFrom: {db.syncOutbox, db.uploadQueue},
      )
      .watchSingle()
      .map((row) => row.read<int>('n'));
});

/// Versão "só o número" (0 enquanto o stream não emitiu) para a UI que não
/// quer lidar com `AsyncValue`.
final pendingSyncCountProvider = Provider<int>(
  (ref) => ref.watch(pendingSyncCountStreamProvider).value ?? 0,
);

/// Operações de escrita ainda na outbox (para a tela "Alterações pendentes").
final pendingOutboxProvider =
    StreamProvider.autoDispose<List<SyncOutboxData>>((ref) {
      if (kIsWeb) return Stream.value(const []);
      final AppDatabase db;
      try {
        db = ref.watch(appDatabaseProvider);
      } catch (_) {
        return Stream.value(const []);
      }
      return db.select(db.syncOutbox).watch().map(
        (rows) => rows..sort((a, b) => a.occurredAt.compareTo(b.occurredAt)),
      );
    });

/// Anexos (foto/assinatura) ainda na fila de upload.
final pendingUploadsListProvider =
    StreamProvider.autoDispose<List<UploadQueueData>>((ref) {
      if (kIsWeb) return Stream.value(const []);
      final AppDatabase db;
      try {
        db = ref.watch(appDatabaseProvider);
      } catch (_) {
        return Stream.value(const []);
      }
      return db.select(db.uploadQueue).watch().map(
        (rows) => rows..sort((a, b) => a.createdAt.compareTo(b.createdAt)),
      );
    });

/// Ações da tela "Alterações pendentes": reenviar tudo e descartar item a item.
class PendingChangesController {
  PendingChangesController(this._ref);
  final Ref _ref;

  Future<void> retryAll() =>
      _ref.read(syncRunnerProvider.notifier).refreshEverything();

  Future<void> discardOutbox(String operationId) async {
    await _ref.read(syncEngineProvider).discardOperation(operationId);
    _ref.invalidate(pendingOutboxProvider);
  }

  /// Descarta um anexo da fila. O arquivo local fica (limpeza é melhor
  /// esforço e depende de `dart:io`); some sozinho quando o app for
  /// reinstalado.
  Future<void> discardUpload(String id) async {
    final db = _ref.read(appDatabaseProvider);
    await (db.delete(db.uploadQueue)..where((t) => t.id.equals(id))).go();
    _ref.invalidate(pendingUploadsListProvider);
  }
}

final pendingChangesControllerProvider = Provider(
  PendingChangesController.new,
);
