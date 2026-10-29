import 'package:comfy_list/shared/data/secure/secure_session_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const flagKey = 'session.emailVerified';

  SecureSessionStore storeWith([Map<String, String> initial = const {}]) {
    FlutterSecureStorage.setMockInitialValues({...initial});
    return SecureSessionStore();
  }

  group('SecureSessionStore.emailVerified', () {
    test('ausente es desconocido (null)', () async {
      expect(await storeWith().readEmailVerified(), isNull);
    });

    test('guarda y lee true y false', () async {
      final store = storeWith();

      await store.saveEmailVerified(true);
      expect(await store.readEmailVerified(), isTrue);

      await store.saveEmailVerified(false);
      expect(await store.readEmailVerified(), isFalse);
    });

    test('clear() lo borra', () async {
      final store = storeWith();
      await store.saveEmailVerified(true);

      await store.clear();

      expect(await store.readEmailVerified(), isNull);
    });

    test('saveSession no lo toca', () async {
      final store = storeWith({flagKey: 'true'});

      await store.saveSession(idToken: 'i', refreshToken: 'r', uid: 'u-1');

      expect(await store.readEmailVerified(), isTrue);
    });

    test('saveSession no lo crea', () async {
      final store = storeWith();

      await store.saveSession(idToken: 'i', refreshToken: 'r', uid: 'u-1');

      expect(await store.readEmailVerified(), isNull);
    });

    test('un valor corrupto cuenta como desconocido', () async {
      expect(await storeWith({flagKey: 'x'}).readEmailVerified(), isNull);
    });
  });
}
