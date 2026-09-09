import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'attachment_cache.dart';

/// Web: sem banco local nem `dart:io` — o cache não existe (o app roda
/// sempre online).
class _NoopAttachmentCache implements AttachmentCache {
  const _NoopAttachmentCache();

  @override
  Future<List<CachedAttachment>> forOwner(String ownerKind, String ownerId) async =>
      const [];

  @override
  Future<void> adoptUploaded({
    required String photoId,
    required String ownerKind,
    required String ownerId,
    required String kind,
    required String sourceFilePath,
    String? serviceOrderItemId,
    String? caption,
  }) async {}

  @override
  Future<void> syncPhotos(
    String ownerKind,
    String ownerId,
    List<RemoteAttachment> photos,
  ) async {}

  @override
  Future<void> syncSignature(
    String serviceOrderId,
    RemoteAttachment? signature,
  ) async {}

  @override
  Future<void> forget(String photoId) async {}
}

AttachmentCache createAttachmentCache(Ref ref) => const _NoopAttachmentCache();
