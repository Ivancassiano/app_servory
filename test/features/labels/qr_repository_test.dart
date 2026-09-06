import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servory/core/db/app_database.dart';
import 'package:servory/core/connectivity/connectivity_provider.dart';
import 'package:servory/core/network/api_client.dart';
import 'package:servory/core/providers.dart';
import 'package:servory/features/auth/application/session_controller.dart';
import 'package:servory/features/labels/data/qr_mapper.dart';
import 'package:servory/features/labels/data/qr_repository.dart';
import 'package:servory/features/sync/application/sync_provider.dart';

import '../../support/stub_dio.dart';

void main() {
  group('qrCodeFromApiJson', () {
    test('mapeia o shape QRCode e datas', () {
      final c = qrCodeFromApiJson(const {
        'id': 'q1',
        'public_code': 'SL-8K4P-7M2Q-RT9X-C3NW-A',
        'status': 'assigned',
        'equipment_id': 'e1',
        'assigned_at': '2026-03-04T05:06:07Z',
        'version': 2,
      }, organizationId: 'org1');
      expect(c.id, 'q1');
      expect(c.publicCode, 'SL-8K4P-7M2Q-RT9X-C3NW-A');
      expect(c.status, 'assigned');
      expect(c.equipmentId, 'e1');
      expect(c.assignedAt, DateTime.utc(2026, 3, 4, 5, 6, 7));
      expect(c.syncStatus, 'synced');
    });

    test('public_code ausente vira null (etiqueta offline sem código)', () {
      final c = qrCodeFromApiJson(
        const {'id': 'q2', 'status': 'available', 'version': 1},
        organizationId: 'org1',
      );
      expect(c.publicCode, isNull);
    });
  });

  test('QrResolved.fromApiJson lê code + entity', () {
    final r = QrResolved.fromApiJson(const {
      'code': {'id': 'q1', 'status': 'assigned', 'equipment_id': 'e9'},
      'entity': {
        'kind': 'equipment',
        'id': 'e9',
        'name': 'Forno 3',
        'location_id': 'l1',
      },
    }, organizationId: 'org1');
    expect(r.code.id, 'q1');
    expect(r.entity!.kind, 'equipment');
    expect(r.entity!.name, 'Forno 3');
    expect(r.entity!.locationId, 'l1');
  });

  test('QrTarget: igualdade serve de chave de family', () {
    expect(const QrTarget.client('c1'), const QrTarget.client('c1'));
    expect(
      const QrTarget.client('c1') == const QrTarget.location('c1'),
      isFalse,
    );
  });

  test('app: watchActive lê a etiqueta assigned do cache drift', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await db.into(db.localQrCodes).insert(
          LocalQrCodesCompanion.insert(
            id: 'q1',
            organizationId: 'org1',
            status: 'assigned',
            publicCode: const Value('SL-AAAA-BBBB-CCCC-DDDD-E'),
            equipmentId: const Value('e1'),
            assignedAt: Value(DateTime.utc(2026, 1, 1)),
            localUpdatedAt: DateTime.now(),
          ),
        );
    // etiqueta antiga desativada do mesmo equipamento não deve aparecer
    await db.into(db.localQrCodes).insert(
          LocalQrCodesCompanion.insert(
            id: 'q0',
            organizationId: 'org1',
            status: 'deactivated',
            equipmentId: const Value('e1'),
            localUpdatedAt: DateTime.now(),
          ),
        );

    final stub = StubDio((_) => (status: 200, body: {'results': <dynamic>[]}));
    final c = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        apiClientProvider.overrideWithValue(_FakeApiClient(stub.dio)),
        sessionControllerProvider.overrideWith(_FakeSession.new),
      ],
    );
    addTearDown(c.dispose);

    final active = await c
        .read(qrRepositoryProvider)
        .watchActive(const QrTarget.equipment('e1'))
        .first;
    expect(active?.id, 'q1');
    expect(active?.publicCode, 'SL-AAAA-BBBB-CCCC-DDDD-E');
  });

  group('ações offline (app)', () {
    Future<ProviderContainer> container(AppDatabase db, StubDio stub) async {
      final c = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          apiClientProvider.overrideWithValue(_FakeApiClient(stub.dio)),
          isOnlineProvider.overrideWith((ref) => Stream.value(false)),
          sessionControllerProvider.overrideWith(_FakeSession.new),
        ],
      );
      addTearDown(c.dispose);
      c.listen(isOnlineProvider, (_, _) {});
      await pumpEventQueue();
      return c;
    }

    test('assign de código desconhecido offline → QrActionException', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final stub = StubDio((_) => (status: 200, body: {'results': <dynamic>[]}));
      final c = await container(db, stub);

      expect(
        () => c.read(qrRepositoryProvider).assign(
              codeId: 'nao-conheco',
              target: const QrTarget.client('c1'),
            ),
        throwsA(isA<QrActionException>()),
      );
    });

    test('assign de código no inventário local → drift pending + outbox', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      await db.into(db.localQrCodes).insert(
            LocalQrCodesCompanion.insert(
              id: 'q1',
              organizationId: 'org1',
              status: 'reserved',
              publicCode: const Value('SL-Z'),
              version: const Value(1),
              localUpdatedAt: DateTime.now(),
            ),
          );
      final stub = StubDio((_) => (status: 200, body: {'results': <dynamic>[]}));
      final c = await container(db, stub);

      await c.read(qrRepositoryProvider).assign(
            codeId: 'q1',
            target: const QrTarget.equipment('e9'),
            baseVersion: 1,
          );

      final row =
          await (db.select(db.localQrCodes)..where((t) => t.id.equals('q1')))
              .getSingle();
      expect(row.status, 'assigned');
      expect(row.equipmentId, 'e9');
      expect(row.syncStatus, 'pending');
      final outbox = await db.select(db.syncOutbox).getSingle();
      expect(outbox.entityType, 'qr_code');
      expect(outbox.operationType, 'assign');
      expect(outbox.baseVersion, 1);
    });

    test('deactivate offline → drift + outbox', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      await db.into(db.localQrCodes).insert(
            LocalQrCodesCompanion.insert(
              id: 'q2',
              organizationId: 'org1',
              status: 'assigned',
              equipmentId: const Value('e1'),
              localUpdatedAt: DateTime.now(),
            ),
          );
      final stub = StubDio((_) => (status: 200, body: {'results': <dynamic>[]}));
      final c = await container(db, stub);

      await c.read(qrRepositoryProvider).deactivate(codeId: 'q2');

      final row =
          await (db.select(db.localQrCodes)..where((t) => t.id.equals('q2')))
              .getSingle();
      expect(row.status, 'deactivated');
      final outbox = await db.select(db.syncOutbox).getSingle();
      expect(outbox.operationType, 'deactivate');
    });

    test('replace sem newCodeId offline → QrActionException', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      await db.into(db.localQrCodes).insert(
            LocalQrCodesCompanion.insert(
              id: 'q3',
              organizationId: 'org1',
              status: 'assigned',
              clientId: const Value('c1'),
              localUpdatedAt: DateTime.now(),
            ),
          );
      final stub = StubDio((_) => (status: 200, body: {'results': <dynamic>[]}));
      final c = await container(db, stub);

      expect(
        () => c.read(qrRepositoryProvider).replace(codeId: 'q3'),
        throwsA(isA<QrActionException>()),
      );
    });
  });

  test('resolve: GET /v1/qr-codes/resolve/{code}', () async {
    RequestOptions? got;
    final stub = StubDio((req) {
      got = req;
      return (
        status: 200,
        body: {
          'code': {'id': 'q1', 'status': 'assigned', 'client_id': 'c1'},
          'entity': {'kind': 'client', 'id': 'c1', 'name': 'Padaria'},
        },
      );
    });
    final c = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(_FakeApiClient(stub.dio)),
        sessionControllerProvider.overrideWith(_FakeSession.new),
        appDatabaseProvider.overrideWithValue(
          AppDatabase.forTesting(NativeDatabase.memory()),
        ),
      ],
    );
    addTearDown(c.dispose);

    final r = await c.read(qrRepositoryProvider).resolve('SL 8K4P 7M2Q');
    expect(got!.path, contains('/v1/qr-codes/resolve/'));
    expect(r.entity!.name, 'Padaria');
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
