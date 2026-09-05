import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Resposta canned para uma requisição.
typedef StubHandler = ({int status, Object body}) Function(RequestOptions req);

/// `Dio` real com um adapter que devolve JSON canned — exercita a
/// serialização de verdade do Dio sem rede.
class StubDio {
  StubDio(this._handler)
    : dio = Dio(BaseOptions(baseUrl: 'http://stub')) {
    dio.httpClientAdapter = _StubAdapter(_handler, _log);
  }

  final StubHandler _handler;
  final Dio dio;
  final List<RequestOptions> _log = [];

  List<RequestOptions> get requests => List.unmodifiable(_log);
  RequestOptions get lastRequest => _log.last;
}

class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this._handler, this._log);
  final StubHandler _handler;
  final List<RequestOptions> _log;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    _log.add(options);
    final r = _handler(options);
    return ResponseBody.fromString(
      jsonEncode(r.body),
      r.status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
