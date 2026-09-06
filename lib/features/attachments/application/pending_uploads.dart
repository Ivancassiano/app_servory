/// Acesso à fila de upload pendente, seguro no web (onde ela não existe —
/// o envio é sempre online e imediato).
library;

export 'pending_uploads_io.dart'
    if (dart.library.js_interop) 'pending_uploads_web.dart';
