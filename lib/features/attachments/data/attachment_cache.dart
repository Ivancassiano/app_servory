import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'attachment_cache_stub.dart'
    if (dart.library.io) 'attachment_cache_io.dart';

/// Uma foto/assinatura já no servidor cuja cópia local o app guarda para
/// mostrar offline.
class CachedAttachment {
  const CachedAttachment({
    required this.photoId,
    required this.ownerKind,
    required this.ownerId,
    required this.kind,
    required this.localPath,
    this.serviceOrderItemId,
    this.caption,
  });

  final String photoId;
  final String ownerKind; // service_order | item | location
  final String ownerId;
  final String kind; // 'photo' | 'signature'
  final String localPath;
  final String? serviceOrderItemId;
  final String? caption;
}

/// Um anexo do servidor a caber no cache: id + URL de download (assinada e
/// temporária) + metadados.
class RemoteAttachment {
  const RemoteAttachment({
    required this.photoId,
    required this.url,
    this.serviceOrderItemId,
    this.caption,
  });

  final String photoId;
  final String url;
  final String? serviceOrderItemId;
  final String? caption;
}

/// Cache local de anexos (foto/assinatura) para vê-los sem conexão. No web é
/// um no-op — lá o app roda sempre online e não há banco local.
abstract class AttachmentCache {
  /// Anexos em cache de um dono (`ownerKind` ∈ service_order|item|location).
  Future<List<CachedAttachment>> forOwner(String ownerKind, String ownerId);

  /// Um upload deste aparelho concluiu: registra o arquivo já capturado
  /// (não copia — o gerador de PDF local também usa esse arquivo).
  Future<void> adoptUploaded({
    required String photoId,
    required String ownerKind,
    required String ownerId,
    required String kind,
    required String sourceFilePath,
    String? serviceOrderItemId,
    String? caption,
  });

  /// Alinha o cache de fotos de um dono com o servidor: baixa as que faltam,
  /// atualiza legendas, remove as que sumiram.
  Future<void> syncPhotos(
    String ownerKind,
    String ownerId,
    List<RemoteAttachment> photos,
  );

  /// Idem para a assinatura de uma ordem (`null` = ordem sem assinatura).
  Future<void> syncSignature(String serviceOrderId, RemoteAttachment? signature);

  /// Esquece um anexo (foto removida no servidor / apagada pelo usuário).
  Future<void> forget(String photoId);
}

/// Chave sintética da assinatura de uma ordem no cache (não tem id próprio
/// de "foto").
String signatureCacheId(String serviceOrderId) => 'sig:$serviceOrderId';

final attachmentCacheProvider = Provider<AttachmentCache>(createAttachmentCache);
