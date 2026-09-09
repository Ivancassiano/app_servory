import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:servory/core/connectivity/connectivity_provider.dart';
import 'package:servory/core/db/app_database.dart';
import 'package:servory/features/attachments/application/attachments_api_provider.dart';
import 'package:servory/features/attachments/application/service_order_attachments_provider.dart';
import 'package:servory/features/attachments/data/attachment_cache.dart';
import 'package:servory/features/attachments/data/attachment_cache_io.dart';
import 'package:servory/features/attachments/data/attachments_api.dart';
import 'package:servory/features/auth/application/session_controller.dart';
import 'package:servory/features/sync/application/sync_provider.dart';

class MockAttachmentsApi extends Mock implements AttachmentsApi {}

void main() {
  late AppDatabase db;
  late Directory tmp;
  late MockAttachmentsApi api;
  late StreamController<bool> online;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    tmp = Directory.systemTemp.createTempSync('entity_photos_test');
    api = MockAttachmentsApi();
    online = StreamController<bool>(); // nunca emite → isOnline fica null (tenta online)
    addTearDown(() {
      online.close();
      db.close();
      if (tmp.existsSync()) tmp.deleteSync(recursive: true);
    });
  });

  ProviderContainer makeContainer() {
    final c = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        organizationIdProvider.overrideWithValue('org1'),
        attachmentsApiProvider.overrideWithValue(api),
        // Conectividade "online" — mas as chamadas de API abaixo falham, como
        // quando o wi-fi está ligado mas fora da rede do servidor.
        isOnlineProvider.overrideWith((ref) => online.stream),
        attachmentCacheProvider.overrideWith(
          (ref) => AttachmentCacheIo(
            ref,
            download: (_) async => throw StateError('não deve baixar no teste'),
            cacheDir: Directory(p.join(tmp.path, 'cache')),
          ),
        ),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  Future<void> seedCachedPhoto(ProviderContainer c) async {
    final f = File(p.join(tmp.path, 'own.jpg'))..writeAsBytesSync([1, 2, 3]);
    await c.read(attachmentCacheProvider).adoptUploaded(
      photoId: 'srv-1',
      ownerKind: 'item',
      ownerId: 'it-1',
      kind: 'photo',
      sourceFilePath: f.path,
      caption: 'de campo',
    );
  }

  void stubListThrows() {
    when(
      () => api.listPhotos(
        ownerKind: any(named: 'ownerKind'),
        ownerId: any(named: 'ownerId'),
      ),
    ).thenThrow(const SocketException('conexão recusada'));
  }

  test('servidor inalcançável: cai no cache em vez de erro', () async {
    final c = makeContainer();
    await seedCachedPhoto(c);
    stubListThrows();

    final photos = await c.read(entityPhotosProvider(('item', 'it-1')).future);

    expect(photos, hasLength(1));
    expect(photos.single.id, 'srv-1');
    expect(photos.single.localPath, isNotNull);
    expect(photos.single.caption, 'de campo');
  });

  test('servidor inalcançável e nada em cache: fica em erro, não vazio', () async {
    final c = makeContainer();
    stubListThrows();
    final sub = c.listen(entityPhotosProvider(('item', 'it-9')), (_, _) {});
    addTearDown(sub.close);

    for (var i = 0; i < 50 && sub.read().isLoading; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(sub.read().hasError, isTrue);
  });

  test('a URL de download falha mas a foto está em cache: mostra do disco', () async {
    final c = makeContainer();
    await seedCachedPhoto(c);
    when(
      () => api.listPhotos(
        ownerKind: any(named: 'ownerKind'),
        ownerId: any(named: 'ownerId'),
      ),
    ).thenAnswer(
      (_) async => [
        {'id': 'srv-1', 'kind': 'other', 'caption': 'de campo'},
      ],
    );
    when(
      () => api.photoDownloadUrl(
        ownerKind: any(named: 'ownerKind'),
        ownerId: any(named: 'ownerId'),
        photoId: any(named: 'photoId'),
      ),
    ).thenThrow(const SocketException('timeout'));

    final photos = await c.read(entityPhotosProvider(('item', 'it-1')).future);

    expect(photos.single.id, 'srv-1');
    expect(photos.single.localPath, isNotNull);
  });
}
