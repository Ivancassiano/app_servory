import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'attachment_controller.dart';
import 'attachments_api_provider.dart';
import 'service_order_attachments_provider.dart';

AttachmentController createAttachmentController(Ref ref) =>
    _WebAttachmentController(ref);

/// Web: envia direto (sempre online) e invalida o cache de anexos já
/// enviados para a seção da tela recarregar.
class _WebAttachmentController implements AttachmentController {
  _WebAttachmentController(this._ref);
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
  }) async {
    await _ref.read(attachmentsApiProvider).addPhoto(
      ownerKind: ownerKind,
      ownerId: ownerId,
      bytes: bytes,
      filename: filename,
      kind: photoKind,
      caption: caption,
      serviceOrderItemId: serviceOrderItemId,
    );
    _ref.invalidate(entityPhotosProvider((ownerKind, ownerId)));
  }

  @override
  Future<void> submitSignature({
    required String orderId,
    required Uint8List bytes,
  }) async {
    await _ref.read(attachmentsApiProvider).putSignature(
      serviceOrderId: orderId,
      bytes: bytes,
    );
    _ref.invalidate(orderSignatureProvider(orderId));
  }
}
