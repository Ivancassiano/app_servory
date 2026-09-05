import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'upload_queue_provider.dart';

export 'upload_queue_provider.dart' show uploadQueueForOrderProvider;

/// Drena a fila de upload pendente (nativo). Chamado de telas → `WidgetRef`.
Future<void> drainPendingUploads(WidgetRef ref) =>
    ref.read(uploadQueueRunnerProvider.notifier).drain();
