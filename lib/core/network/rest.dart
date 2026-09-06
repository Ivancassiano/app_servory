import 'package:dio/dio.dart';

import 'api_exception.dart';

/// Executa uma chamada Dio "crua" e converte `DioException` no
/// [ApiException] de domínio (mesmo contrato de `SyncApi`/`MeApi`). Falha de
/// rede/timeout vira `code == 'NETWORK_ERROR'` — os repositórios usam isso
/// para decidir entre "erro pro usuário" e "cair pra fila offline".
Future<Response<dynamic>> restCall(
  Future<Response<dynamic>> Function() call,
) async {
  try {
    return await call();
  } on DioException catch (e) {
    throw ApiException.fromDio(e);
  }
}

/// `true` quando o erro é ausência de conexão (não uma rejeição do servidor).
bool isOfflineError(Object error) =>
    error is ApiException && error.code == 'NETWORK_ERROR';
