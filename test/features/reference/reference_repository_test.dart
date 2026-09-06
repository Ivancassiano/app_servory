import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servory/core/db/app_database.dart';
import 'package:servory/core/network/api_client.dart';
import 'package:servory/core/providers.dart';
import 'package:servory/features/auth/application/session_controller.dart';
import 'package:servory/features/reference/data/reference_repository.dart';
import 'package:servory/features/sync/application/sync_provider.dart';

import '../../support/stub_dio.dart';

void main() {
  group('referenceItemFromApiJson', () {
    test('service_order_type / company usam id + name', () {
      final t = referenceItemFromApiJson(
        ReferenceKind.serviceOrderType,
        const {'id': 't1', 'name': 'Manutenção'},
      );
      expect(t.id, 't1');
      expect(t.label, 'Manutenção');
      expect(t.subtitle, '');
    });

    test('org_user usa user_id e mostra e-mail no subtítulo', () {
      final u = referenceItemFromApiJson(
        ReferenceKind.orgUser,
        const {'user_id': 'u1', 'name': 'Ana', 'email': 'ana@x.com'},
      );
      expect(u.id, 'u1');
      expect(u.label, 'Ana');
      expect(u.subtitle, 'ana@x.com');
    });

    test('org_user sem nome cai pro e-mail como label', () {
      final u = referenceItemFromApiJson(
        ReferenceKind.orgUser,
        const {'user_id': 'u2', 'name': '', 'email': 'b@x.com'},
      );
      expect(u.label, 'b@x.com');
      expect(u.subtitle, '');
    });
  });

  test('app: refresh baixa e cacheia; watchList emite ordenado por label', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final stub = StubDio((req) {
      if (req.path == '/v1/service-order-types') {
        return (
          status: 200,
          body: {
            'service_order_types': [
              {'id': 't2', 'name': 'Zebra'},
              {'id': 't1', 'name': 'Alfa'},
            ],
          },
        );
      }
      return (status: 200, body: {'results': <dynamic>[]});
    });
    final c = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        apiClientProvider.overrideWithValue(_FakeApiClient(stub.dio)),
        sessionControllerProvider.overrideWith(_FakeSession.new),
      ],
    );
    addTearDown(c.dispose);

    final repo = c.read(referenceDataRepositoryProvider);
    await repo.refresh(ReferenceKind.serviceOrderType);

    final rows = await db.select(db.localReferenceData).get();
    expect(rows.map((r) => r.id).toSet(), {'t1', 't2'});
    expect(rows.every((r) => r.kind == 'service_order_type'), isTrue);

    final list = await repo
        .watchList(ReferenceKind.serviceOrderType)
        .first;
    expect(list.map((i) => i.label), ['Alfa', 'Zebra']);
  });

  test('app: refresh substitui o cache anterior (remove itens sumidos)', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    var second = false;
    final stub = StubDio((req) {
      if (req.path == '/v1/companies') {
        final body = second
            ? {
                'companies': [
                  {'id': 'co2', 'name': 'Nova'},
                ],
              }
            : {
                'companies': [
                  {'id': 'co1', 'name': 'Antiga'},
                  {'id': 'co2', 'name': 'Nova'},
                ],
              };
        return (status: 200, body: body);
      }
      return (status: 200, body: {'results': <dynamic>[]});
    });
    final c = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        apiClientProvider.overrideWithValue(_FakeApiClient(stub.dio)),
        sessionControllerProvider.overrideWith(_FakeSession.new),
      ],
    );
    addTearDown(c.dispose);
    final repo = c.read(referenceDataRepositoryProvider);

    await repo.refresh(ReferenceKind.company);
    expect((await db.select(db.localReferenceData).get()).length, 2);

    second = true;
    await repo.refresh(ReferenceKind.company);
    final rows = await db.select(db.localReferenceData).get();
    expect(rows.map((r) => r.id).toList(), ['co2']);
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
