import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/connectivity/connectivity_provider.dart';
import '../data/attachment_cache.dart';
import 'attachments_api_provider.dart';

/// Foto já enviada, com a URL de download já resolvida (o servidor nunca
/// devolve o binário direto — só uma URL assinada e temporária,
/// GUIA-FLUTTER.md §26.4). Serve para ordem de serviço, item e local.
class EntityPhoto {
  const EntityPhoto({
    required this.id,
    required this.downloadUrl,
    this.kind,
    this.caption,
    this.serviceOrderItemId,
    this.localPath,
  });

  final String id;
  final String downloadUrl;
  final String? kind;
  final String? caption;

  /// Item da visita a que a foto pertence — só faz sentido em fotos de OS;
  /// `null` = foto geral.
  final String? serviceOrderItemId;

  /// Cópia local (cache offline), quando existe — a UI prefere ela à
  /// `downloadUrl` (mais rápido e funciona offline).
  final String? localPath;
}

/// Compat: código antigo ainda usa `OrderPhoto`.
typedef OrderPhoto = EntityPhoto;

class OrderSignature {
  const OrderSignature({
    required this.id,
    required this.downloadUrl,
    this.localPath,
  });

  final String id;
  final String downloadUrl;
  final String? localPath;
}

/// Fotos são REST puro (não fazem parte do sync). Online: busca a lista +
/// URLs assinadas e, em segundo plano, guarda uma cópia local (cache
/// offline). Offline: devolve o que está em cache — as fotos já vistas uma
/// vez continuam aparecendo (a fila de upload local, `uploadQueueForOwner`,
/// mostra as ainda não enviadas). Chave `(ownerKind, ownerId)` —
/// ownerKind ∈ {service_order, item, location}.
final entityPhotosProvider =
    FutureProvider.family<List<EntityPhoto>, (String, String)>((ref, key) async {
      final online = ref.watch(isOnlineProvider).value;
      final cache = ref.watch(attachmentCacheProvider);

      if (online == false) {
        final cached = await cache.forOwner(key.$1, key.$2);
        return [
          for (final c in cached)
            if (c.kind == 'photo')
              EntityPhoto(
                id: c.photoId,
                downloadUrl: '',
                localPath: c.localPath,
                caption: c.caption,
                serviceOrderItemId: c.serviceOrderItemId,
              ),
        ];
      }

      final api = ref.watch(attachmentsApiProvider);
      final photos = await api.listPhotos(ownerKind: key.$1, ownerId: key.$2);
      final byId = {
        for (final c in await cache.forOwner(key.$1, key.$2)) c.photoId: c,
      };
      final resolved = <EntityPhoto>[];
      final toCache = <RemoteAttachment>[];
      for (final photo in photos) {
        final id = photo['id'] as String;
        try {
          final url = await api.photoDownloadUrl(
            ownerKind: key.$1,
            ownerId: key.$2,
            photoId: id,
          );
          final caption = photo['caption'] as String?;
          final soItem = photo['service_order_item_id'] as String?;
          toCache.add(
            RemoteAttachment(
              photoId: id,
              url: url,
              caption: caption,
              serviceOrderItemId: soItem,
            ),
          );
          resolved.add(
            EntityPhoto(
              id: id,
              downloadUrl: url,
              kind: photo['kind'] as String?,
              caption: caption,
              serviceOrderItemId: soItem,
              localPath: byId[id]?.localPath,
            ),
          );
        } catch (_) {
          continue;
        }
      }
      unawaited(cache.syncPhotos(key.$1, key.$2, toCache));
      return resolved;
    });

/// Compat: fotos de uma ordem de serviço.
final orderPhotosProvider = FutureProvider.family<List<EntityPhoto>, String>((
  ref,
  serviceOrderId,
) => ref.watch(entityPhotosProvider(('service_order', serviceOrderId)).future));

final orderSignatureProvider = FutureProvider.family<OrderSignature?, String>((
  ref,
  serviceOrderId,
) async {
  final online = ref.watch(isOnlineProvider).value;
  final cache = ref.watch(attachmentCacheProvider);
  final sigId = signatureCacheId(serviceOrderId);

  if (online == false) {
    final cached = await cache.forOwner('service_order', serviceOrderId);
    for (final c in cached) {
      if (c.kind == 'signature') {
        return OrderSignature(
          id: sigId,
          downloadUrl: '',
          localPath: c.localPath,
        );
      }
    }
    return null;
  }

  final api = ref.watch(attachmentsApiProvider);
  final data = await api.getSignature(serviceOrderId);
  if (data == null) {
    unawaited(cache.syncSignature(serviceOrderId, null));
    return null;
  }
  final url = await api.signatureDownloadUrl(serviceOrderId);
  unawaited(
    cache.syncSignature(
      serviceOrderId,
      RemoteAttachment(photoId: sigId, url: url),
    ),
  );
  String? local;
  for (final c in await cache.forOwner('service_order', serviceOrderId)) {
    if (c.kind == 'signature') local = c.localPath;
  }
  return OrderSignature(
    id: data['id'] as String,
    downloadUrl: url,
    localPath: local,
  );
});
