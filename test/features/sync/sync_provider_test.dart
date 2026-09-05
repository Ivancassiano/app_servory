import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
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

  test(
    'runSync esvazia a outbox (push) ANTES de puxar (pull)',
    () async {
      // Ordem importa (achado real): uma ação recente (ex.: `start`) deixa
      // no servidor um evento de outbox ainda não puxado. Puxar antes de
      // empurrar aplicaria esse estado "velho" por cima de uma escrita
      // local otimista mais nova (ex.: `complete`) ainda só na outbox —
      // o push seguinte só corrigiria `version`, não os outros campos.
      await container.read(syncRunnerProvider.notifier).runSync();

      verifyInOrder([() => engine.pushPending(), () => engine.pull()]);
      verifyNever(() => engine.bootstrap());
    },
  );

  test('runSync(bootstrap: true) faz bootstrap e depois drena a outbox', () async {
    await container.read(syncRunnerProvider.notifier).runSync(bootstrap: true);

    verifyInOrder([() => engine.bootstrap(), () => engine.pushPending()]);
    verifyNever(() => engine.pull());
  });
}
