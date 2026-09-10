import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../data/attachment_cache.dart';
import 'attachment_controller.dart';
import 'attachments_api_provider.dart';
import 'service_order_attachments_provider.dart';
import 'upload_queue_controller.dart';

AttachmentController createAttachmentController(Ref ref) =>
    _IoAttachmentController(ref);

/// Nativo: delega à fila de upload offline.
class _IoAttachmentController implements AttachmentController {
  _IoAttachmentController(this._ref);
  final Ref _ref;

  @override
  Future<void> submitPhoto({
    required String ownerKind,
    required String ownerId,
    required Uint8List bytes,
    required String filename,
    String photoKind = 'other',
    String? caption,
    String? serviceOrderItemId,
  }) => _ref.read(uploadQueueControllerProvider).enqueuePhoto(
    ownerKind: ownerKind,
    ownerId: ownerId,
    bytes: bytes,
    extension: p.extension(filename),
    photoKind: photoKind,
    caption: caption,
    serviceOrderItemId: serviceOrderItemId,
  );

  @override
  Future<void> submitSignature({
    required String orderId,
    required Uint8List bytes,
  }) => _ref.read(uploadQueueControllerProvider).enqueueSignature(
    serviceOrderId: orderId,
    bytes: bytes,
  );

  @override
  Future<void> deletePhoto({
    required String ownerKind,
    required String ownerId,
    required String photoId,
  }) async {
    await _ref.read(attachmentsApiProvider).deletePhoto(
      ownerKind: ownerKind,
      ownerId: ownerId,
      photoId: photoId,
    );
    await _ref.read(attachmentCacheProvider).forget(photoId);
    _ref.invalidate(entityPhotosProvider((ownerKind, ownerId)));
  }
}
