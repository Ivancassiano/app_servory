/// Regras de senha que o backend exige — espelha `validatePassword` de
/// `internal/iam/password_policy.go` no `auth_servory`. **Se mudar lá, mude
/// aqui.**
///
/// O *enforcement* é sempre do backend (rejeita com `WEAK_PASSWORD`); este
/// arquivo existe só para o feedback visual ao vivo no formulário. É a única
/// definição da regra no app: os `validator` dos campos também passam por
/// [PasswordPolicy.isValid].
library;

/// Uma condição da senha e se o texto atual a satisfaz.
class PasswordRule {
  const PasswordRule({required this.label, required this.satisfied});

  final String label;
  final bool satisfied;
}

abstract final class PasswordPolicy {
  /// Comprimento mínimo, em pontos de código Unicode (== Go
  /// `internal/iam/password_policy.go` → `minPasswordLen`).
  static const minLength = 8;

  /// Comprimento máximo (== Go `maxPasswordLen`). Sem regra visível no
  /// checklist — o campo já limita a digitação; a checagem aqui cobre um
  /// texto colado.
  static const maxLength = 128;

  static final _upper = RegExp(r'\p{Lu}', unicode: true);
  static final _lower = RegExp(r'\p{Ll}', unicode: true);
  static final _digit = RegExp(r'[0-9]');
  // "Símbolo" = qualquer coisa que não seja letra, número ou espaço — igual ao
  // `default` do switch no Go.
  static final _symbol = RegExp(r'[^\p{L}\p{N}\s]', unicode: true);

  /// Avalia [password] contra cada regra, na ordem de exibição.
  static List<PasswordRule> evaluate(String password) => [
    PasswordRule(
      label: 'Pelo menos $minLength caracteres',
      satisfied: password.runes.length >= minLength,
    ),
    PasswordRule(
      label: 'Uma letra maiúscula',
      satisfied: _upper.hasMatch(password),
    ),
    PasswordRule(
      label: 'Uma letra minúscula',
      satisfied: _lower.hasMatch(password),
    ),
    PasswordRule(label: 'Um número', satisfied: _digit.hasMatch(password)),
    PasswordRule(
      label: 'Um símbolo (ex.: ! @ # -)',
      satisfied: _symbol.hasMatch(password),
    ),
  ];

  /// `true` quando todas as regras passam e o texto não estoura [maxLength].
  static bool isValid(String password) =>
      password.runes.length <= maxLength &&
      evaluate(password).every((r) => r.satisfied);

  /// Mensagem única para os `validator` de formulário (mesmo teor do backend).
  static const requirementMessage =
      'A senha precisa ter ao menos $minLength caracteres, com maiúscula, '
      'minúscula, número e símbolo.';
}
