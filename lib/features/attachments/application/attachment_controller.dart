import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'attachment_controller_io.dart'
    if (dart.library.js_interop) 'attachment_controller_web.dart' as impl;

/// Envio de foto/assinatura de uma ordem. Duas implementações:
/// - nativo: salva os bytes em disco + fila de upload offline
///   (`UploadQueueController`);
/// - web: `POST multipart` direto (sempre online), sem fila nem disco.
abstract interface class AttachmentController {
  Future<void> submitPhoto({
    required String orderId,
    required Uint8List bytes,
    required String filename,
    required String photoKind,
    String? caption,
  });

  Future<void> submitSignature({
    required String orderId,
    required Uint8List bytes,
  });
}

final attachmentControllerProvider = Provider<AttachmentController>(
  (ref) => impl.createAttachmentController(ref),
);
