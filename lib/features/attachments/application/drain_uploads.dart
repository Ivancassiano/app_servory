/// Drena a fila de upload de anexos (foto/assinatura) usando um [Ref] —
/// para o `SyncRunner` (que não tem `WidgetRef`). No web é um no-op: lá o
/// upload é sempre online e imediato, sem fila.
library;

export 'drain_uploads_stub.dart'
    if (dart.library.io) 'drain_uploads_io.dart';
