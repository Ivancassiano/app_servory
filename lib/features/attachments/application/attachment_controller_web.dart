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
    required String orderId,
    required Uint8List bytes,
    required String filename,
    required String photoKind,
    String? caption,
  }) async {
    await _ref.read(attachmentsApiProvider).addPhoto(
      serviceOrderId: orderId,
      bytes: bytes,
      filename: filename,
      kind: photoKind,
      caption: caption,
    );
    _ref.invalidate(orderPhotosProvider(orderId));
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
