import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import 'attachment_controller.dart';
import 'upload_queue_controller.dart';

AttachmentController createAttachmentController(Ref ref) =>
    _IoAttachmentController(ref);

/// Nativo: delega à fila de upload offline.
class _IoAttachmentController implements AttachmentController {
  _IoAttachmentController(this._ref);
  final Ref _ref;

  @override
  Future<void> submitPhoto({
    required String orderId,
    required Uint8List bytes,
    required String filename,
    required String photoKind,
    String? caption,
  }) => _ref.read(uploadQueueControllerProvider).enqueuePhoto(
    serviceOrderId: orderId,
    bytes: bytes,
    extension: p.extension(filename),
    photoKind: photoKind,
    caption: caption,
  );

  @override
  Future<void> submitSignature({
    required String orderId,
    required Uint8List bytes,
  }) => _ref.read(uploadQueueControllerProvider).enqueueSignature(
    serviceOrderId: orderId,
    bytes: bytes,
  );
}
