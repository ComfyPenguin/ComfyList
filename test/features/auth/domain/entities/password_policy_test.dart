import 'package:comfy_list/features/auth/domain/entities/password_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PasswordPolicy', () {
    test('exige la longitud mínima', () {
      expect(PasswordPolicy.minLength, 8);
      expect(PasswordRule.minLength.isMetBy('abcdefg'), isFalse);
      expect(PasswordRule.minLength.isMetBy('abcdefgh'), isTrue);
    });

    test('no basta con la longitud: pide letra y número', () {
      expect(PasswordPolicy.unmet('12345678'), [PasswordRule.letter]);
      expect(PasswordPolicy.unmet('abcdefgh'), [PasswordRule.number]);
      expect(PasswordPolicy.isValid('12345678'), isFalse);
      expect(PasswordPolicy.isValid('abcdefgh'), isFalse);
    });

    test('las letras con tilde y la eñe cuentan como letra', () {
      expect(PasswordRule.letter.isMetBy('ñ'), isTrue);
      expect(PasswordRule.letter.isMetBy('á'), isTrue);
      expect(PasswordPolicy.isValid('contraseña1'), isTrue);
    });

    test('lista lo que falta y se queda vacía al cumplirla', () {
      expect(PasswordPolicy.unmet(''), PasswordRule.values);
      expect(PasswordPolicy.unmet('abcdefg1'), isEmpty);
      expect(PasswordPolicy.isValid('abcdefg1'), isTrue);
    });
  });
}
