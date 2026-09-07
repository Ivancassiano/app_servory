import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servory/core/db/app_database.dart';
import 'package:servory/core/network/api_client.dart';
import 'package:servory/core/providers.dart';
import 'package:servory/features/auth/application/session_controller.dart';
import 'package:servory/features/items/data/item_type_repository.dart';
import 'package:servory/features/sync/application/sync_provider.dart';

import '../../support/stub_dio.dart';

void main() {
  test('refresh substitui o cache — tipo apagado no servidor some', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    // Lixo pré-existente no cache local (ex.: base anterior).
    await db
        .into(db.localItemTypes)
        .insert(
          LocalItemTypesCompanion.insert(
            id: 'lixo-1',
            organizationId: 'org1',
            name: 'Antigo A',
            cachedAt: DateTime.now(),
          ),
        );
    await db
        .into(db.localItemTypes)
        .insert(
          LocalItemTypesCompanion.insert(
            id: 'lixo-2',
            organizationId: 'org1',
            name: 'Antigo B',
            cachedAt: DateTime.now(),
          ),
        );

    final stub = StubDio(
      (req) => (
        status: 200,
        body: {
          'item_types': [
            {'id': 'novo-1', 'name': 'Ar-condicionado', 'version': 1},
          ],
        },
      ),
    );
    final c = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        apiClientProvider.overrideWithValue(_FakeApiClient(stub.dio)),
        sessionControllerProvider.overrideWith(_FakeSession.new),
      ],
    );
    addTearDown(c.dispose);

    await c.read(itemTypeRepositoryProvider).refresh();

    final rows = await db.select(db.localItemTypes).get();
    expect(rows.map((t) => t.id), ['novo-1']);
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
  SessionState build() =>
      const SessionAuthenticated(userId: 'u1', organizationId: 'org1');
}
