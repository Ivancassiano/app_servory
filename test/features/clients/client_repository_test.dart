import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servory/core/connectivity/connectivity_provider.dart';
import 'package:servory/core/db/app_database.dart';
import 'package:servory/core/network/api_client.dart';
import 'package:servory/core/providers.dart';
import 'package:servory/features/auth/application/session_controller.dart';
import 'package:servory/features/clients/data/client_repository.dart';
import 'package:servory/features/sync/application/sync_provider.dart';

import '../../support/stub_dio.dart';

void main() {
  group('RemoteClientRepository (web)', () {
    test('watchList busca /v1/clients e mapeia', () async {
      final stub = StubDio((req) {
        expect(req.path, '/v1/clients');
        return (
          status: 200,
          body: {
            'clients': [
              {'id': 'c1', 'name': 'Alfa', 'kind': 'legal', 'version': 1},
              {'id': 'c2', 'name': 'Beta', 'kind': 'legal', 'version': 1},
            ],
            'total': 2,
          },
        );
      });
      final repo = RemoteClientRepository(stub.dio, 'org1');
      final list = await repo.watchList().firstWhere((l) => l.isNotEmpty);
      expect(list.map((c) => c.name), ['Alfa', 'Beta']);
    });

    test('create faz POST e devolve o id do servidor + entra no cache',
        () async {
      var posted = false;
      final stub = StubDio((req) {
        if (req.method == 'POST') {
          posted = true;
          expect(req.data, {'kind': 'legal', 'name': 'Nova', 'phone': '11'});
          return (
            status: 201,
            body: {'id': 'srv-1', 'name': 'Nova', 'kind': 'legal', 'version': 1},
          );
        }
        return (status: 200, body: {'clients': <dynamic>[]});
      });
      final repo = RemoteClientRepository(stub.dio, 'org1');
      // ignore: unused_local_variable
      final sub = repo.watchList().listen((_) {});
      final id = await repo.create(kind: 'legal', name: 'Nova', phone: '11');
      expect(posted, isTrue);
      expect(id, 'srv-1');
      final list = await repo.watchList().first;
      expect(list.single.id, 'srv-1');
      await sub.cancel();
    });

    test('update faz PATCH com version', () async {
      final stub = StubDio((req) {
        if (req.method == 'PATCH') {
          expect(req.path, '/v1/clients/c1');
          expect(req.data, {'name': 'Renomeado', 'phone': '9', 'version': 4});
          return (
            status: 200,
            body: {'id': 'c1', 'name': 'Renomeado', 'kind': 'legal', 'version': 5},
          );
        }
        return (status: 200, body: {'clients': <dynamic>[]});
      });
      final repo = RemoteClientRepository(stub.dio, 'org1');
      await repo.update(
        id: 'c1',
        baseVersion: 4,
        name: 'Renomeado',
        phone: '9',
      );
    });
  });

  group('LocalFirstClientRepository (app)', () {
    late AppDatabase db;
    late ProviderContainer container;
    late StubDio stub;

    Future<ProviderContainer> build({
      required bool online,
      required StubHandler handler,
    }) async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      stub = StubDio(handler);
      final c = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          apiClientProvider.overrideWithValue(_FakeApiClient(stub.dio)),
          isOnlineProvider.overrideWith((ref) => Stream.value(online)),
          sessionControllerProvider.overrideWith(_FakeSession.new),
        ],
      );
      addTearDown(c.dispose);
      addTearDown(db.close);
      // ativa e deixa o StreamProvider de conectividade emitir o 1º valor
      c.listen(isOnlineProvider, (_, _) {});
      await pumpEventQueue();
      return c;
    }

    test('online: cria via REST, aquece o cache, sem linha de outbox',
        () async {
      container = await build(
        online: true,
        handler: (req) {
          if (req.path == '/v1/clients' && req.method == 'POST') {
            return (
              status: 201,
              body: {
                'id': 'srv-9',
                'name': 'OnlineCo',
                'kind': 'legal',
                'version': 1,
              },
            );
          }
          return (status: 200, body: {'results': <dynamic>[]});
        },
      );
      final repo = container.read(clientRepositoryProvider);
      final id = await repo.create(
        kind: 'legal',
        name: 'OnlineCo',
        phone: '',
      );
      expect(id, 'srv-9');

      final rows = await db.select(db.localClients).get();
      expect(rows.single.name, 'OnlineCo');
      expect(rows.single.syncStatus, 'synced');
      final outbox = await db.select(db.syncOutbox).get();
      expect(outbox, isEmpty);
    });

    test('offline: grava local pendente + linha de outbox', () async {
      container = await build(
        online: false,
        handler: (req) => (status: 200, body: {'results': <dynamic>[]}),
      );
      final repo = container.read(clientRepositoryProvider);
      final id = await repo.create(kind: 'legal', name: 'OfflineCo', phone: '');

      final rows = await db.select(db.localClients).get();
      expect(rows.single.id, id);
      expect(rows.single.syncStatus, 'pending');
      final outbox = await db.select(db.syncOutbox).get();
      expect(outbox.single.entityType, 'client');
      expect(outbox.single.operationType, 'create');
    });
  });
}

class _FakeApiClient implements ApiClient {
  _FakeApiClient(this.businessDio);
  @override
  final Dio businessDio;
  @override
  Dio get authDio => businessDio;
}

class _FakeSession extends SessionController {
  @override
  SessionState build() => const SessionAuthenticated(
        userId: 'u1',
        organizationId: 'org1',
      );
}
