import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';

/// No web não há fila local — o upload é sempre online e imediato. A lista
/// de pendentes é sempre vazia.
final uploadQueueForOrderProvider =
    StreamProvider.family<List<UploadQueueData>, String>(
  (ref, orderId) => Stream.value(const <UploadQueueData>[]),
);

Future<void> drainPendingUploads(WidgetRef ref) async {}
