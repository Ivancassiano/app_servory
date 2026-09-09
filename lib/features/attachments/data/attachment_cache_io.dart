import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/db/app_database.dart';
import '../../auth/application/session_controller.dart' show organizationIdProvider;
import '../../sync/application/sync_provider.dart';
import 'attachment_cache.dart';

/// Teto do cache baixado (só os arquivos sob `attachments/cache/`; os de
/// captura própria ficam de fora — o gerador de PDF precisa deles).
const _maxCacheBytes = 250 * 1024 * 1024;

/// Baixa os bytes de uma URL (injetável nos testes).
typedef AttachmentDownloader = Future<Uint8List> Function(String url);

class AttachmentCacheIo implements AttachmentCache {
  AttachmentCacheIo(
    this._ref, {
    AttachmentDownloader? download,
    Directory? cacheDir,
  }) : _download = download ?? _defaultDownload,
       _cacheDirOverride = cacheDir;

  final Ref _ref;
  final AttachmentDownloader _download;
  final Directory? _cacheDirOverride;

  static Future<Uint8List> _defaultDownload(String url) async {
    final res = await Dio().get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(res.data ?? const []);
  }

  AppDatabase? get _db {
    try {
      return _ref.read(appDatabaseProvider);
    } catch (_) {
      return null; // sem sessão — nada a cachear
    }
  }

  String? get _orgId {
    try {
      return _ref.read(organizationIdProvider);
    } catch (_) {
      return null; // sem sessão
    }
  }

  Future<Directory> _cacheDir() async {
    final dir =
        _cacheDirOverride ??
        Directory(
          p.join(
            (await getApplicationDocumentsDirectory()).path,
            'attachments',
            'cache',
          ),
        );
    await dir.create(recursive: true);
    return dir;
  }

  @override
  Future<List<CachedAttachment>> forOwner(
    String ownerKind,
    String ownerId,
  ) async {
    final db = _db;
    if (db == null) return const [];
    final rows =
        await (db.select(db.localPhotoCache)..where(
              (t) => t.ownerKind.equals(ownerKind) & t.ownerId.equals(ownerId),
            ))
            .get();
    final out = <CachedAttachment>[];
    for (final r in rows) {
      // Um arquivo sumido (limpeza do SO, "limpar dados" parcial) — descarta
      // a linha em vez de devolver um caminho quebrado.
      if (!File(r.localPath).existsSync()) {
        await _deleteRow(db, r.photoId, r.localPath);
        continue;
      }
      out.add(
        CachedAttachment(
          photoId: r.photoId,
          ownerKind: r.ownerKind,
          ownerId: r.ownerId,
          kind: r.kind,
          localPath: r.localPath,
          serviceOrderItemId: r.serviceOrderItemId,
          caption: r.caption,
        ),
      );
    }
    return out;
  }

  @override
  Future<void> adoptUploaded({
    required String photoId,
    required String ownerKind,
    required String ownerId,
    required String kind,
    required String sourceFilePath,
    String? serviceOrderItemId,
    String? caption,
  }) async {
    final db = _db;
    final org = _orgId;
    if (db == null || org == null) return;
    if (!File(sourceFilePath).existsSync()) return;
    await db
        .into(db.localPhotoCache)
        .insertOnConflictUpdate(
          LocalPhotoCacheCompanion.insert(
            photoId: photoId,
            organizationId: org,
            ownerKind: ownerKind,
            ownerId: ownerId,
            kind: kind,
            localPath: sourceFilePath,
            cachedAt: DateTime.now(),
            serviceOrderItemId: Value(serviceOrderItemId),
            caption: Value(caption),
          ),
        );
  }

  @override
  Future<void> syncPhotos(
    String ownerKind,
    String ownerId,
    List<RemoteAttachment> photos,
  ) async {
    final db = _db;
    final org = _orgId;
    if (db == null || org == null) return;

    final known = {
      for (final r
          in await (db.select(db.localPhotoCache)..where(
                (t) =>
                    t.ownerKind.equals(ownerKind) &
                    t.ownerId.equals(ownerId) &
                    t.kind.equals('photo'),
              ))
              .get())
        r.photoId: r,
    };
    final wanted = {for (final a in photos) a.photoId};

    // Some do servidor → some do cache.
    for (final gone in known.keys.where((id) => !wanted.contains(id))) {
      await _deleteRow(db, gone, known[gone]!.localPath);
    }

    for (final a in photos) {
      final existing = known[a.photoId];
      if (existing != null) {
        // Já em cache: só mantém a legenda em dia.
        if (existing.caption != a.caption ||
            existing.serviceOrderItemId != a.serviceOrderItemId) {
          await (db.update(db.localPhotoCache)
                ..where((t) => t.photoId.equals(a.photoId)))
              .write(
                LocalPhotoCacheCompanion(
                  caption: Value(a.caption),
                  serviceOrderItemId: Value(a.serviceOrderItemId),
                ),
              );
        }
        continue;
      }
      await _fetchInto(
        db,
        org,
        photoId: a.photoId,
        ownerKind: ownerKind,
        ownerId: ownerId,
        kind: 'photo',
        url: a.url,
        serviceOrderItemId: a.serviceOrderItemId,
        caption: a.caption,
      );
    }
    await _trim(db);
  }

  @override
  Future<void> syncSignature(
    String serviceOrderId,
    RemoteAttachment? signature,
  ) async {
    final db = _db;
    final org = _orgId;
    if (db == null || org == null) return;
    final id = signatureCacheId(serviceOrderId);
    final existing = await (db.select(
      db.localPhotoCache,
    )..where((t) => t.photoId.equals(id))).getSingleOrNull();

    if (signature == null) {
      if (existing != null) await _deleteRow(db, id, existing.localPath);
      return;
    }
    if (existing != null) return; // assinatura não muda depois de coletada
    await _fetchInto(
      db,
      org,
      photoId: id,
      ownerKind: 'service_order',
      ownerId: serviceOrderId,
      kind: 'signature',
      url: signature.url,
    );
    await _trim(db);
  }

  @override
  Future<void> forget(String photoId) async {
    final db = _db;
    if (db == null) return;
    final row = await (db.select(
      db.localPhotoCache,
    )..where((t) => t.photoId.equals(photoId))).getSingleOrNull();
    if (row != null) await _deleteRow(db, photoId, row.localPath);
  }

  Future<void> _fetchInto(
    AppDatabase db,
    String org, {
    required String photoId,
    required String ownerKind,
    required String ownerId,
    required String kind,
    required String url,
    String? serviceOrderItemId,
    String? caption,
  }) async {
    try {
      final bytes = await _download(url);
      if (bytes.isEmpty) return;
      final dir = await _cacheDir();
      final file = File(p.join(dir.path, photoId.replaceAll(':', '_')));
      await file.writeAsBytes(bytes, flush: true);
      await db
          .into(db.localPhotoCache)
          .insertOnConflictUpdate(
            LocalPhotoCacheCompanion.insert(
              photoId: photoId,
              organizationId: org,
              ownerKind: ownerKind,
              ownerId: ownerId,
              kind: kind,
              localPath: file.path,
              cachedAt: DateTime.now(),
              serviceOrderItemId: Value(serviceOrderItemId),
              caption: Value(caption),
            ),
          );
    } catch (_) {
      // Rede/disco falhou: sem cache desta foto agora, tenta de novo depois.
    }
  }

  Future<void> _deleteRow(AppDatabase db, String photoId, String path) async {
    await (db.delete(
      db.localPhotoCache,
    )..where((t) => t.photoId.equals(photoId))).go();
    await _deleteFileIfCached(path);
  }

  /// Só apaga o arquivo se ele estiver sob `attachments/cache/` — os de
  /// captura própria são compartilhados com o gerador de PDF.
  Future<void> _deleteFileIfCached(String path) async {
    try {
      final dir = await _cacheDir();
      if (p.isWithin(dir.path, path)) {
        final f = File(path);
        if (await f.exists()) await f.delete();
      }
    } catch (_) {}
  }

  /// Poda o cache baixado por tamanho (LRU pelo `cachedAt`). Não toca nos
  /// arquivos de captura própria.
  Future<void> _trim(AppDatabase db) async {
    try {
      final dir = await _cacheDir();
      final rows =
          await (db.select(db.localPhotoCache)
                ..orderBy([(t) => OrderingTerm.asc(t.cachedAt)]))
              .get();
      var total = 0;
      final sized = <(String photoId, String path, int bytes)>[];
      for (final r in rows) {
        if (!p.isWithin(dir.path, r.localPath)) continue;
        final f = File(r.localPath);
        final len = f.existsSync() ? f.lengthSync() : 0;
        total += len;
        sized.add((r.photoId, r.localPath, len));
      }
      for (final entry in sized) {
        if (total <= _maxCacheBytes) break;
        await _deleteRow(db, entry.$1, entry.$2);
        total -= entry.$3;
      }
    } catch (_) {}
  }
}

AttachmentCache createAttachmentCache(Ref ref) => AttachmentCacheIo(ref);
