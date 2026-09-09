import 'package:flutter_test/flutter_test.dart';
import 'package:servory/features/auth/domain/password_policy.dart';

void main() {
  test('minLength espelha o backend (internal/iam/iam.go)', () {
    expect(PasswordPolicy.minLength, 8);
  });

  test('isValid: só passa com 8+ caracteres', () {
    expect(PasswordPolicy.isValid(''), isFalse);
    expect(PasswordPolicy.isValid('1234567'), isFalse);
    expect(PasswordPolicy.isValid('12345678'), isTrue);
    expect(PasswordPolicy.isValid('uma senha bem longa'), isTrue);
  });

  test('conta pontos de código, não unidades UTF-16 (== Go []rune)', () {
    // 8 emojis = 8 runes, mas 16 code units UTF-16
    expect('😀😀😀😀😀😀😀😀'.length, 16);
    expect(PasswordPolicy.isValid('😀😀😀😀😀😀😀😀'), isTrue);
    expect(PasswordPolicy.isValid('😀😀😀😀😀😀😀'), isFalse);
  });

  test('evaluate devolve a regra com o estado atual', () {
    final short = PasswordPolicy.evaluate('abc');
    expect(short, hasLength(1));
    expect(short.single.label, 'Pelo menos 8 caracteres');
    expect(short.single.satisfied, isFalse);

    expect(PasswordPolicy.evaluate('abcdefgh').single.satisfied, isTrue);
  });
}
