import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/connectivity/connectivity_provider.dart';
import 'attachments_api_provider.dart';

/// Foto já enviada, com a URL de download já resolvida (o servidor nunca
/// devolve o binário direto — só uma URL assinada e temporária,
/// GUIA-FLUTTER.md §26.4).
class OrderPhoto {
  const OrderPhoto({
    required this.id,
    required this.downloadUrl,
    this.kind,
    this.caption,
  });

  final String id;
  final String downloadUrl;
  final String? kind;
  final String? caption;
}

class OrderSignature {
  const OrderSignature({required this.id, required this.downloadUrl});

  final String id;
  final String downloadUrl;
}

/// Fotos/assinatura são REST puro (não fazem parte do sync) — só busca
/// quando online; offline devolve vazio/nulo sem tentar rede (a fila de
/// upload local, `uploadQueueForOrderProvider`, já mostra o que está
/// pendente de envio independente de conexão).
final orderPhotosProvider = FutureProvider.family<List<OrderPhoto>, String>((
  ref,
  serviceOrderId,
) async {
  final online = ref.watch(isOnlineProvider).value;
  if (online == false) return const [];
  final api = ref.watch(attachmentsApiProvider);
  final photos = await api.listPhotos(serviceOrderId);
  final resolved = <OrderPhoto>[];
  for (final photo in photos) {
    final id = photo['id'] as String;
    try {
      final url = await api.photoDownloadUrl(
        serviceOrderId: serviceOrderId,
        photoId: id,
      );
      resolved.add(
        OrderPhoto(
          id: id,
          downloadUrl: url,
          kind: photo['kind'] as String?,
          caption: photo['caption'] as String?,
        ),
      );
    } catch (_) {
      // Uma foto com URL de download indisponível não deve derrubar a
      // galeria inteira — ela só não aparece, as outras seguem normais.
      continue;
    }
  }
  return resolved;
});

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
