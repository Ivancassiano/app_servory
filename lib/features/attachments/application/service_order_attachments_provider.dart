import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/connectivity/connectivity_provider.dart';
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
  });

  final String id;
  final String downloadUrl;
  final String? kind;
  final String? caption;

  /// Item da visita a que a foto pertence — só faz sentido em fotos de OS;
  /// `null` = foto geral.
  final String? serviceOrderItemId;
}

/// Compat: código antigo ainda usa `OrderPhoto`.
typedef OrderPhoto = EntityPhoto;

class OrderSignature {
  const OrderSignature({required this.id, required this.downloadUrl});

  final String id;
  final String downloadUrl;
}

/// Fotos são REST puro (não fazem parte do sync) — só busca quando online;
/// offline devolve vazio sem tentar rede (a fila de upload local,
/// `uploadQueueForOwnerProvider`, já mostra o pendente). Chave
/// `(ownerKind, ownerId)` — ownerKind ∈ {service_order, item, location}.
final entityPhotosProvider =
    FutureProvider.family<List<EntityPhoto>, (String, String)>((ref, key) async {
      final online = ref.watch(isOnlineProvider).value;
      if (online == false) return const [];
      final api = ref.watch(attachmentsApiProvider);
      final photos = await api.listPhotos(ownerKind: key.$1, ownerId: key.$2);
      final resolved = <EntityPhoto>[];
      for (final photo in photos) {
        final id = photo['id'] as String;
        try {
          final url = await api.photoDownloadUrl(
            ownerKind: key.$1,
            ownerId: key.$2,
            photoId: id,
          );
          resolved.add(
            EntityPhoto(
              id: id,
              downloadUrl: url,
              kind: photo['kind'] as String?,
              caption: photo['caption'] as String?,
              serviceOrderItemId: photo['service_order_item_id'] as String?,
            ),
          );
        } catch (_) {
          continue;
        }
      }
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
  if (online == false) return null;
  final api = ref.watch(attachmentsApiProvider);
  final data = await api.getSignature(serviceOrderId);
  if (data == null) return null;
  final url = await api.signatureDownloadUrl(serviceOrderId);
  return OrderSignature(id: data['id'] as String, downloadUrl: url);
});
