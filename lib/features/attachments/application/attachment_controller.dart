import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'attachment_controller_io.dart'
    if (dart.library.js_interop) 'attachment_controller_web.dart' as impl;

/// Envio de foto/assinatura de uma ordem. Duas implementações:
/// - nativo: salva os bytes em disco + fila de upload offline
///   (`UploadQueueController`);
/// - web: `POST multipart` direto (sempre online), sem fila nem disco.
abstract interface class AttachmentController {
  /// [ownerKind] ∈ {service_order, item, location}; [ownerId] é o dono da foto.
  Future<void> submitPhoto({
    required String ownerKind,
    required String ownerId,
    required Uint8List bytes,
    required String filename,
    String photoKind = 'other',
    String? caption,
    String? serviceOrderItemId,
  });

  Future<void> submitSignature({
    required String orderId,
    required Uint8List bytes,
  });

  /// Apaga uma foto já enviada (REST puro, precisa de conexão) e recarrega a
  /// galeria do dono.
  Future<void> deletePhoto({
    required String ownerKind,
    required String ownerId,
    required String photoId,
  });
}

final attachmentControllerProvider = Provider<AttachmentController>(
  (ref) => impl.createAttachmentController(ref),
);
