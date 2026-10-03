import 'package:comfy_list/features/auth/domain/entities/email_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EmailPolicy', () {
    test('acepta correos normales', () {
      expect(EmailPolicy.isValid('ana@correo.com'), isTrue);
      expect(EmailPolicy.isValid('ana.garcia+comfy@sub.dominio.es'), isTrue);
      expect(EmailPolicy.isValid('a_b-c@dominio.io'), isTrue);
      expect(EmailPolicy.isValid('ana@correo.e'), isTrue);
    });

    test('ignora los espacios de los extremos del autocompletado', () {
      expect(EmailPolicy.isValid('  ana@correo.com  '), isTrue);
    });

    test('rechaza lo que el servidor rechazaría', () {
      expect(EmailPolicy.isValid(''), isFalse);
      expect(EmailPolicy.isValid('ana'), isFalse);
      expect(EmailPolicy.isValid('ana@'), isFalse);
      expect(EmailPolicy.isValid('@correo.com'), isFalse);
      expect(EmailPolicy.isValid('ana@correo'), isFalse);
      expect(EmailPolicy.isValid('ana correo@dominio.com'), isFalse);
      expect(EmailPolicy.isValid('ana@dominio..com'), isFalse);
      expect(EmailPolicy.isValid('ana@-dominio.com'), isFalse);
    });
  });
}
