/// Regras de senha que o backend exige — espelha `minPasswordLen` de
/// `internal/iam/iam.go` no `auth_servory`. **Se mudar lá, mude aqui.**
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
  /// Comprimento mínimo, em pontos de código Unicode (== Go `len([]rune(s))`,
  /// `internal/iam/iam.go` → `minPasswordLen`).
  static const minLength = 8;

  /// Avalia [password] contra cada regra, na ordem de exibição.
  static List<PasswordRule> evaluate(String password) => [
    PasswordRule(
      label: 'Pelo menos $minLength caracteres',
      satisfied: password.runes.length >= minLength,
    ),
  ];

  /// `true` quando todas as regras passam.
  static bool isValid(String password) =>
      evaluate(password).every((r) => r.satisfied);

  /// Mensagem única para os `validator` de formulário (mesmo texto do backend).
  static const requirementMessage =
      'A senha precisa ter pelo menos $minLength caracteres.';
}
