import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/providers.dart';
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

  /// "Atualizar tudo": além do sync (push + pull), recarrega o que é REST
  /// puro e fica FORA do protocolo de sync — fotos e assinatura, cuja URL de
  /// download é assinada e temporária (§26.4) — e limpa o cache de imagens,
  /// pra as miniaturas resolverem a URL nova (ex.: quando o host do storage
  /// muda). É o botão da faixa de status em todas as telas.
  Future<void> refreshEverything() async {
    await runSync();
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
