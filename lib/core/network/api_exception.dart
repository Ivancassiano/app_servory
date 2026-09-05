import 'package:dio/dio.dart';

/// Erro de domínio da API, construído a partir do envelope estável
/// `{ "error": { "code", "message", "details", "request_id" } }`
/// (spec §22.1). O app trata sempre por [code] — nunca por [message], que é
/// só para log/depuração (GUIA-FLUTTER.md §6).
class ApiException implements Exception {
  const ApiException({
    required this.code,
    required this.message,
    this.statusCode,
    this.requestId,
  });

  /// Erro sem resposta HTTP legível (timeout, sem conexão, etc.).
  factory ApiException.network(DioException cause) {
    return const ApiException(
      code: 'NETWORK_ERROR',
      message: 'Não foi possível conectar ao servidor.',
    );
  }

  factory ApiException.fromDio(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['error'] is Map) {
      final err = data['error'] as Map;
      return ApiException(
        code: (err['code'] as String?) ?? 'UNKNOWN',
        message: (err['message'] as String?) ?? 'Erro desconhecido.',
        statusCode: e.response?.statusCode,
        requestId: err['request_id'] as String?,
      );
    }
    return ApiException.network(e);
  }

  final String code;
  final String message;
  final int? statusCode;
  final String? requestId;

  /// Mensagem amigável em PT para os códigos mais comuns; cai para uma
  /// mensagem genérica quando o código não é conhecido pelo cliente (um
  /// código novo no backend nunca deve travar o app).
  String get friendlyMessage => _friendlyByCode[code] ?? _genericMessage;

  static const _genericMessage = 'Não foi possível completar a ação. Tente novamente.';

  static const _friendlyByCode = <String, String>{
    'INVALID_CREDENTIALS': 'E-mail ou senha inválidos.',
    'USER_INACTIVE': 'Este usuário está inativo. Fale com um administrador.',
    'NO_ACTIVE_ORGANIZATION': 'Nenhuma organização ativa para este usuário.',
    'ORGANIZATION_NOT_RESOLVED': 'Não foi possível determinar a organização ativa.',
    'INVALID_REFRESH_TOKEN': 'Sua sessão expirou. Entre novamente.',
    'INVALID_RESET_TOKEN': 'Link de redefinição inválido ou expirado.',
    'INVALID_INVITATION': 'Convite inválido ou já utilizado.',
    'WEAK_PASSWORD': 'A senha é muito fraca.',
    'RATE_LIMITED': 'Muitas tentativas. Aguarde um instante e tente de novo.',
    'FORBIDDEN': 'Você não tem permissão para fazer isso.',
    'UNAUTHORIZED': 'Sua sessão expirou. Entre novamente.',
    'NOT_FOUND': 'Registro não encontrado.',
    'VERSION_CONFLICT': 'Este registro foi alterado por outra pessoa. Recarregue e tente de novo.',
    'NETWORK_ERROR': 'Não foi possível conectar ao servidor. Verifique sua conexão.',
    'INTERNAL': _genericMessage,
  };

  @override
  String toString() => 'ApiException($code, $message)';
}
