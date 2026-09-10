import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:servory/core/db/app_database.dart';
import 'package:servory/features/sync/application/sync_engine.dart';
import 'package:servory/features/sync/application/sync_provider.dart';

class MockSyncEngine extends Mock implements SyncEngine {}

void main() {
  late MockSyncEngine engine;
  late ProviderContainer container;

  setUp(() {
    engine = MockSyncEngine();
    when(() => engine.pushPending()).thenAnswer((_) async {});
    when(() => engine.pull()).thenAnswer((_) async {});
    when(() => engine.bootstrap()).thenAnswer((_) async {});
    container = ProviderContainer(
      overrides: [syncEngineProvider.overrideWithValue(engine)],
    );
  });

  tearDown(() => container.dispose());

  test('runSync esvazia a outbox (push) ANTES de puxar (pull)', () async {
    // Ordem importa (achado real): uma ação recente (ex.: `start`) deixa
    // no servidor um evento de outbox ainda não puxado. Puxar antes de
    // empurrar aplicaria esse estado "velho" por cima de uma escrita
    // local otimista mais nova (ex.: `complete`) ainda só na outbox —
    // o push seguinte só corrigiria `version`, não os outros campos.
    await container.read(syncRunnerProvider.notifier).runSync();

    verifyInOrder([() => engine.pushPending(), () => engine.pull()]);
    verifyNever(() => engine.bootstrap());
  });

  test(
    'runSync(bootstrap: true) faz bootstrap e depois drena a outbox',
    () async {
      await container
          .read(syncRunnerProvider.notifier)
          .runSync(bootstrap: true);

      verifyInOrder([() => engine.bootstrap(), () => engine.pushPending()]);
      verifyNever(() => engine.pull());
    },
  );

  group('pendingSyncCountProvider', () {
    late AppDatabase db;
    late ProviderContainer c;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      c = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(c.dispose);
      addTearDown(db.close);
    });

    Future<void> expectCount(int want) async {
      for (var i = 0; i < 100; i++) {
        if (c.read(pendingSyncCountProvider) == want) return;
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      fail('pendingSyncCountProvider parou em ${c.read(pendingSyncCountProvider)}, esperava $want');
    }

    test('soma outbox + fila de anexos; 0 quando tudo sincronizado', () async {
      c.listen(pendingSyncCountProvider, (_, _) {});
      await expectCount(0);

      await db.into(db.syncOutbox).insert(
            SyncOutboxCompanion.insert(
              operationId: 'op-1',
              organizationId: 'org-1',
              entityType: 'client',
              entityId: 'c-1',
              operationType: 'create',
              payload: '{}',
              occurredAt: DateTime.now(),
            ),
          );
      await db.into(db.uploadQueue).insert(
            UploadQueueCompanion.insert(
              id: 'u-1',
              organizationId: 'org-1',
              ownerId: 'so-1',
              kind: 'photo',
              filePath: '/tmp/x.jpg',
              sha256: 'abc',
              createdAt: DateTime.now(),
            ),
          );
      await expectCount(2);

      await (db.delete(db.syncOutbox)).go();
      await expectCount(1);
    });
  });
}
