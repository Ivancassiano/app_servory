import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'upload_queue_provider.dart';

/// Melhor esforço: as linhas já estão persistidas, então uma falha aqui só
/// adia o envio.
Future<void> drainUploads(Ref ref) async {
  try {
    await ref.read(uploadQueueRunnerProvider.notifier).drain();
  } catch (_) {}
}
