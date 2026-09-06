import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/attachments_api.dart';

/// Provider isolado num arquivo próprio (sem depender de
/// `upload_queue_provider.dart`/`service_order_attachments_provider.dart`)
/// para os dois poderem se referenciar sem import circular — o runner da
/// fila precisa invalidar o cache de fotos/assinatura já enviadas depois de
/// um upload bem-sucedido.
final attachmentsApiProvider = Provider<AttachmentsApi>(
  (ref) => AttachmentsApi(ref.watch(apiClientProvider).businessDio),
);
