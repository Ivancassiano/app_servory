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

  static const _genericMessage =
      'Não foi possível completar a ação. Tente novamente.';

  static const _friendlyByCode = <String, String>{
    'INVALID_CREDENTIALS': 'E-mail ou senha inválidos.',
    'USER_INACTIVE': 'Este usuário está inativo. Fale com um administrador.',
    'NO_ACTIVE_ORGANIZATION': 'Nenhuma organização ativa para este usuário.',
    'ORGANIZATION_NOT_RESOLVED':
        'Não foi possível determinar a organização ativa.',
    'INVALID_REFRESH_TOKEN': 'Sua sessão expirou. Entre novamente.',
    'INVALID_RESET_TOKEN': 'Código de recuperação inválido ou expirado.',
    'INVALID_INVITATION': 'Convite inválido ou já utilizado.',
    'WEAK_PASSWORD': 'A senha precisa ter pelo menos 8 caracteres.',
    'EMAIL_EXISTS': 'Já existe uma conta com esse e-mail.',
    'ORG_NAME_REQUIRED': 'Informe o nome da organização.',
    'INVALID_EMAIL': 'E-mail inválido.',
    'EMAIL_NOT_VERIFIED':
        'Confirme seu e-mail antes de entrar. Verifique sua caixa de entrada.',
    'INVALID_VERIFICATION_CODE': 'Código inválido ou expirado.',
    'SYSTEM_ROLE': 'Perfil padrão não pode ser alterado. Duplique-o primeiro.',
    'ROLE_IN_USE': 'Este perfil ainda tem membros. Mova-os antes de excluir.',
    'ROLE_KEY_TAKEN': 'Já existe um perfil com esse nome.',
    'UNKNOWN_PERMISSION': 'Permissão desconhecida — atualize o app.',
    'INVALID_EFFECT': 'Efeito de permissão inválido.',
    'RATE_LIMITED': 'Muitas tentativas. Aguarde um instante e tente de novo.',
    'FORBIDDEN': 'Você não tem permissão para fazer isso.',
    'UNAUTHORIZED': 'Sua sessão expirou. Entre novamente.',
    'NOT_FOUND': 'Registro não encontrado.',
    'VERSION_CONFLICT':
        'Este registro foi alterado por outra pessoa. Recarregue e tente de novo.',
    'TYPE_LOCKED':
        'Este campo já tem valores preenchidos, então o tipo do dado não pode mudar.',
    'VERSION_REQUIRED':
        'Não foi possível enviar essa edição. Descarte-a e refaça.',
    // Erros de validação que o sync devolve (mesmos códigos do REST).
    'INVALID_FIELD_VALUE':
        'O valor deste campo não é aceito — se for uma lista, a opção pode '
        'ter sido inativada. Abra o item e escolha outra.',
    'FIELD_REQUIRED': 'Um campo obrigatório ficou sem valor. Preencha-o.',
    'FIELD_NOT_APPLICABLE': 'Este campo não se aplica ao tipo do item.',
    'FIELD_DEF_NOT_FOUND': 'Este campo foi removido. Descarte a alteração.',
    'FIELD_FORBIDDEN': 'Você não tem permissão para editar este campo.',
    'CLIENT_NOT_FOUND': 'O cliente desta alteração não existe mais.',
    'LOCATION_NOT_FOUND': 'O local desta alteração não existe mais.',
    'LOCATION_OTHER_CLIENT': 'O local escolhido pertence a outro cliente.',
    'TYPE_NOT_FOUND': 'O tipo escolhido não existe mais. Escolha outro.',
    'TASK_TYPE_NOT_FOUND': 'O tipo de tarefa não existe mais. Escolha outro.',
    'COMPANY_NOT_FOUND': 'A empresa escolhida não existe mais.',
    'ASSIGNEE_NOT_MEMBER': 'O técnico escolhido não faz mais parte da equipe.',
    'TARGET_INVALID': 'Um dos alvos (local/item) não é do cliente da tarefa.',
    'ITEM_NOT_FOUND': 'O item escolhido não existe mais ou é de outro cliente.',
    'INVALID_DATE': 'Data inválida.',
    'INVALID_COST': 'Custo inválido.',
    'INVALID_APPROVAL': 'Aprovação inválida.',
    'INVALID_QUANTITY': 'Quantidade inválida.',
    'INVALID_MONEY': 'Valor em dinheiro inválido.',
    'NOT_EDITABLE': 'A ordem está fechada. Reabra-a antes de editar.',
    'ASSIGN_COMPANY_FORBIDDEN':
        'Você não pode escolher outra empresa para este registro.',
    'COMPANY_ASSIGN_FORBIDDEN':
        'Você não pode escolher outra empresa para este registro.',
    'NETWORK_ERROR':
        'Não foi possível conectar ao servidor. Verifique sua conexão.',
    'INTERNAL': _genericMessage,
  };

  @override
  String toString() => 'ApiException($code, $message)';
}
