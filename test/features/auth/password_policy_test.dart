import 'package:flutter_test/flutter_test.dart';
import 'package:servory/features/auth/domain/password_policy.dart';

void main() {
  test('limites espelham o backend (internal/iam/password_policy.go)', () {
    expect(PasswordPolicy.minLength, 8);
    expect(PasswordPolicy.maxLength, 128);
  });

  test('isValid: exige 8+ caracteres e as quatro classes', () {
    expect(PasswordPolicy.isValid('Senha-forte-1'), isTrue);
    expect(PasswordPolicy.isValid('Aa1!aaaa'), isTrue); // mínimo exato

    expect(PasswordPolicy.isValid(''), isFalse);
    expect(PasswordPolicy.isValid('Aa1!aaa'), isFalse); // 7 caracteres
    expect(PasswordPolicy.isValid('senha-forte-1'), isFalse); // sem maiúscula
    expect(PasswordPolicy.isValid('SENHA-FORTE-1'), isFalse); // sem minúscula
    expect(PasswordPolicy.isValid('Senha-forte!'), isFalse); // sem número
    expect(PasswordPolicy.isValid('SenhaForte12'), isFalse); // sem símbolo
  });

  test('rejeita senha acima de maxLength mesmo cumprindo as classes', () {
    final longa = 'Aa1!' * 33; // 132 caracteres
    expect(PasswordPolicy.isValid(longa), isFalse);
  });

  test('conta pontos de código, não unidades UTF-16 (== Go []rune)', () {
    // "Aã1!" repetido: 'ã' é 1 rune. 7 blocos = 28 runes.
    expect(PasswordPolicy.isValid('Aã1!' * 2), isTrue);
    // emoji sozinho é símbolo, mas não tem letra nem número
    expect(PasswordPolicy.isValid('😀😀😀😀😀😀😀😀'), isFalse);
  });

  test('evaluate devolve as cinco regras com o estado atual', () {
    final rules = PasswordPolicy.evaluate('senha');
    expect(rules, hasLength(5));
    expect(rules.map((r) => r.satisfied).toList(), [
      false, // 8 caracteres
      false, // maiúscula
      true, //  minúscula
      false, // número
      false, // símbolo
    ]);

    final full = PasswordPolicy.evaluate('Senha-forte-1');
    expect(full.every((r) => r.satisfied), isTrue);
  });
}
