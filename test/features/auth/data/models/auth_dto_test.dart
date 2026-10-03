import 'package:comfy_list/features/auth/data/models/auth_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('IdentityAuthResponse', () {
    test('fromJson maps all required fields including optional displayName',
        () {
      final json = <String, dynamic>{
        'idToken': 'i-token',
        'refreshToken': 'r-token',
        'localId': 'u-1',
        'email': 'a@b.c',
        'displayName': 'Ana',
      };

      final res = IdentityAuthResponse.fromJson(json);

      expect(res.idToken, 'i-token');
      expect(res.refreshToken, 'r-token');
      expect(res.localId, 'u-1');
      expect(res.email, 'a@b.c');
      expect(res.displayName, 'Ana');
    });

    test('fromJson leaves displayName null when absent', () {
      final json = <String, dynamic>{
        'idToken': 'i-token',
        'refreshToken': 'r-token',
        'localId': 'u-1',
        'email': 'a@b.c',
      };

      final res = IdentityAuthResponse.fromJson(json);

      expect(res.displayName, isNull);
    });
  });

  group('IdentityLookupUser', () {
    test('fromJson defaults email to empty string when key is absent', () {
      final json = <String, dynamic>{
        'localId': 'u-1',
      };

      final user = IdentityLookupUser.fromJson(json);

      expect(user.localId, 'u-1');
      expect(user.email, '');
      expect(user.displayName, isNull);
    });

    test('fromJson maps displayName when present', () {
      final json = <String, dynamic>{
        'localId': 'u-1',
        'email': 'a@b.c',
        'displayName': 'Ana',
      };

      final user = IdentityLookupUser.fromJson(json);

      expect(user.localId, 'u-1');
      expect(user.email, 'a@b.c');
      expect(user.displayName, 'Ana');
    });

    test('fromJson deja el correo como no verificado si falta la clave', () {
      final user = IdentityLookupUser.fromJson(<String, dynamic>{
        'localId': 'u-1',
      });

      expect(user.emailVerified, isFalse);
    });

    test('fromJson refleja emailVerified cuando viene en la respuesta', () {
      final user = IdentityLookupUser.fromJson(<String, dynamic>{
        'localId': 'u-1',
        'email': 'a@b.c',
        'emailVerified': true,
      });

      expect(user.emailVerified, isTrue);
    });
  });
}
