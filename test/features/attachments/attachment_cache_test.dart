import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:servory/core/db/app_database.dart';
import 'package:servory/features/attachments/data/attachment_cache.dart';
import 'package:servory/features/attachments/data/attachment_cache_io.dart';
import 'package:servory/features/auth/application/session_controller.dart';
import 'package:servory/features/sync/application/sync_provider.dart';

void main() {
  late AppDatabase db;
  late Directory tmp;
  late Directory cacheDir;
  late List<String> fetched;
  late ProviderContainer container;
  late AttachmentCache cache;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    tmp = Directory.systemTemp.createTempSync('attach_cache_test');
    cacheDir = Directory(p.join(tmp.path, 'cache'));
    fetched = [];

    Future<Uint8List> fakeDownload(String url) async {
      fetched.add(url);
      return Uint8List.fromList([1, 2, 3, 4]);
    }

    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        organizationIdProvider.overrideWithValue('org1'),
        attachmentCacheProvider.overrideWith(
          (ref) => AttachmentCacheIo(
            ref,
            download: fakeDownload,
            cacheDir: cacheDir,
          ),
        ),
      ],
    );
    cache = container.read(attachmentCacheProvider);
    addTearDown(() {
      container.dispose();
      db.close();
      if (tmp.existsSync()) tmp.deleteSync(recursive: true);
    });
  });

  File captureFile(String name) {
    final f = File(p.join(tmp.path, name))..writeAsBytesSync([9, 9, 9]);
    return f;
  }

  test('adoptUploaded registra o arquivo já capturado, sem copiar', () async {
    final src = captureFile('own.jpg');
    await cache.adoptUploaded(
      photoId: 'srv-1',
      ownerKind: 'service_order',
      ownerId: 'so-1',
      kind: 'photo',
      sourceFilePath: src.path,
      caption: 'antes',
    );

    final list = await cache.forOwner('service_order', 'so-1');
    expect(list, hasLength(1));
    expect(list.single.photoId, 'srv-1');
    expect(list.single.localPath, src.path);
    expect(list.single.caption, 'antes');
    expect(fetched, isEmpty, reason: 'foto própria não baixa');
  });

  test('syncPhotos baixa as que faltam e remove as que sumiram', () async {
    final src = captureFile('own.jpg');
    await cache.adoptUploaded(
      photoId: 'srv-1',
      ownerKind: 'service_order',
      ownerId: 'so-1',
      kind: 'photo',
      sourceFilePath: src.path,
    );

    // servidor: srv-1 continua + srv-2 é nova (de outro aparelho)
    await cache.syncPhotos('service_order', 'so-1', const [
      RemoteAttachment(photoId: 'srv-1', url: 'http://x/1'),
      RemoteAttachment(photoId: 'srv-2', url: 'http://x/2', caption: 'depois'),
    ]);

    expect(fetched, ['http://x/2'], reason: 'só a nova é baixada');
    final list = await cache.forOwner('service_order', 'so-1');
    expect(list.map((c) => c.photoId).toSet(), {'srv-1', 'srv-2'});
    final two = list.firstWhere((c) => c.photoId == 'srv-2');
    expect(File(two.localPath).existsSync(), isTrue);
    expect(p.isWithin(cacheDir.path, two.localPath), isTrue);

    // servidor agora só tem srv-2 → srv-1 sai do cache
    await cache.syncPhotos('service_order', 'so-1', const [
      RemoteAttachment(photoId: 'srv-2', url: 'http://x/2'),
    ]);
    final after = await cache.forOwner('service_order', 'so-1');
    expect(after.map((c) => c.photoId), ['srv-2']);
    expect(src.existsSync(), isTrue, reason: 'arquivo de captura própria fica');
  });

  test('forget apaga a linha e o arquivo baixado (não o de captura)', () async {
    final src = captureFile('own.jpg');
    await cache.adoptUploaded(
      photoId: 'own',
      ownerKind: 'item',
      ownerId: 'it-1',
      kind: 'photo',
      sourceFilePath: src.path,
    );
    await cache.syncPhotos('item', 'it-1', const [
      RemoteAttachment(photoId: 'own', url: 'http://x/own'),
      RemoteAttachment(photoId: 'dl', url: 'http://x/dl'),
    ]);
    final dl = (await cache.forOwner('item', 'it-1')).firstWhere(
      (c) => c.photoId == 'dl',
    );

    await cache.forget('dl');
    expect(await cache.forOwner('item', 'it-1'), hasLength(1));
    expect(File(dl.localPath).existsSync(), isFalse);

    await cache.forget('own');
    expect(await cache.forOwner('item', 'it-1'), isEmpty);
    expect(src.existsSync(), isTrue, reason: 'forget não toca no arquivo próprio');
  });

  test('forOwner descarta linha cujo arquivo sumiu', () async {
    final src = captureFile('gone.jpg');
    await cache.adoptUploaded(
      photoId: 'ghost',
      ownerKind: 'location',
      ownerId: 'loc-1',
      kind: 'photo',
      sourceFilePath: src.path,
    );
    src.deleteSync();

    expect(await cache.forOwner('location', 'loc-1'), isEmpty);
    final rows = await db.select(db.localPhotoCache).get();
    expect(rows, isEmpty, reason: 'a linha órfã também é removida');
  });

  test('syncSignature baixa uma vez e forget ao remover no servidor', () async {
    await cache.syncSignature(
      'so-9',
      const RemoteAttachment(photoId: 'sig:so-9', url: 'http://x/sig'),
    );
    var list = await cache.forOwner('service_order', 'so-9');
    expect(list.where((c) => c.kind == 'signature'), hasLength(1));
    expect(fetched, ['http://x/sig']);

    // segunda passada não rebaixa
    await cache.syncSignature(
      'so-9',
      const RemoteAttachment(photoId: 'sig:so-9', url: 'http://x/sig2'),
    );
    expect(fetched, ['http://x/sig']);

    await cache.syncSignature('so-9', null);
    list = await cache.forOwner('service_order', 'so-9');
    expect(list.where((c) => c.kind == 'signature'), isEmpty);
  });
}
