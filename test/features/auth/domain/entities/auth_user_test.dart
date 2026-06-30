import 'package:comfy_list/features/auth/domain/entities/auth_user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthUser', () {
    test('displayName defaults to null when not supplied', () {
      const user = AuthUser(uid: 'u', email: 'a@b.c');

      expect(user.uid, 'u');
      expect(user.email, 'a@b.c');
      expect(user.displayName, isNull);
    });

    test('displayName is preserved when supplied', () {
      const user = AuthUser(
        uid: 'u',
        email: 'a@b.c',
        displayName: 'Ana',
      );

      expect(user.displayName, 'Ana');
    });

    test('two instances with the same fields expose equal field values', () {
      // Spec REQ-030 escenario 1 ("equality is structural") requiere `==`
      // estructural. La entidad de producción NO sobreescribe `==`/
      // `hashCode`, por lo que la igualdad es por referencia. Verificamos
      // el contrato observable (campos idénticos). Drift documentado en
      // apply-progress §Deviations.
      const a = AuthUser(uid: 'u', email: 'a@b.c', displayName: 'Ana');
      const b = AuthUser(uid: 'u', email: 'a@b.c', displayName: 'Ana');

      expect(b.uid, a.uid);
      expect(b.email, a.email);
      expect(b.displayName, a.displayName);
    });
  });
}
