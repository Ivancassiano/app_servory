import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../../core/db/app_database.dart';
import '../../auth/application/session_controller.dart';
import '../../sync/application/sync_provider.dart';
import 'upload_queue_provider.dart';

/// Grava o arquivo capturado (foto/assinatura) no diretório do app e
/// enfileira o envio (GUIA-FLUTTER.md §7) — a captura funciona sempre,
/// mesmo offline; só o envio de fato precisa de conexão.
class UploadQueueController {
  UploadQueueController(this._ref);
  final Ref _ref;

  AppDatabase get _db => _ref.read(appDatabaseProvider);

  String get _organizationId {
    final session = _ref.read(sessionControllerProvider);
    if (session is! SessionAuthenticated) {
      throw StateError('UploadQueueController usado sem sessão autenticada');
    }
    return session.organizationId;
  }

  Future<void> enqueuePhoto({
    required String serviceOrderId,
    required File sourceFile,
    required String photoKind,
    String? caption,
  }) => _enqueue(
    serviceOrderId: serviceOrderId,
    sourceFile: sourceFile,
    kind: 'photo',
    photoKind: photoKind,
    caption: caption,
  );

  Future<void> enqueueSignature({
    required String serviceOrderId,
    required File sourceFile,
  }) => _enqueue(
    serviceOrderId: serviceOrderId,
    sourceFile: sourceFile,
    kind: 'signature',
  );

  Future<void> _enqueue({
    required String serviceOrderId,
    required File sourceFile,
    required String kind,
    String? photoKind,
    String? caption,
  }) async {
    final organizationId = _organizationId;
    final id = const Uuid().v4();
    final bytes = await sourceFile.readAsBytes();
    final hash = sha256.convert(bytes).toString();

    final dir = Directory(
      p.join(
        (await getApplicationDocumentsDirectory()).path,
        'attachments',
        serviceOrderId,
      ),
    );
    await dir.create(recursive: true);
    final savedPath = p.join(dir.path, '$id${p.extension(sourceFile.path)}');
    await sourceFile.copy(savedPath);

    await _db
        .into(_db.uploadQueue)
        .insert(
          UploadQueueCompanion.insert(
            id: id,
            organizationId: organizationId,
            serviceOrderId: serviceOrderId,
            kind: kind,
            filePath: savedPath,
            sha256: hash,
            photoKind: Value(photoKind),
            caption: Value(caption),
            createdAt: DateTime.now(),
          ),
        );

    unawaited(_tryDrainNow());
  }

  /// Cancela um item ainda não enviado — apaga arquivo local + linha.
  Future<void> removePending(String id) async {
    final row = await (_db.select(
      _db.uploadQueue,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return;
    await (_db.delete(_db.uploadQueue)..where((t) => t.id.equals(id))).go();
    final file = File(row.filePath);
    if (await file.exists()) await file.delete();
  }

  Future<void> _tryDrainNow() async {
    try {
      await _ref.read(uploadQueueRunnerProvider.notifier).drain();
    } catch (_) {
      // silencioso de propósito: a linha já está na fila e será tentada de
      // novo na próxima sincronização (puxar pra atualizar, ou reabrir a tela).
    }
  }
}

final uploadQueueControllerProvider = Provider<UploadQueueController>(
  (ref) => UploadQueueController(ref),
);
