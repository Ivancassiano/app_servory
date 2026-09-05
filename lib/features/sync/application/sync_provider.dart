import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/providers.dart';
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

/// "Está sincronizando agora?" — a UI usa pra mostrar spinner/erro.
class SyncRunner extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

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
    state = const AsyncValue.loading();
    final engine = ref.read(syncEngineProvider);
    state = await AsyncValue.guard(() async {
      if (bootstrap) {
        await engine.bootstrap();
      } else {
        await engine.pull();
      }
      await engine.pushPending();
    });
  }
}

final syncRunnerProvider = NotifierProvider<SyncRunner, AsyncValue<void>>(
  SyncRunner.new,
);
