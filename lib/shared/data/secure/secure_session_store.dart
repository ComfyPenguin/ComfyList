import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Almacén seguro para los tokens de Firebase Identity Toolkit.
///
/// Se guarda:
///  - idToken (Bearer, expira ~1h)
///  - refreshToken (sin caducidad mientras no se cierre sesión)
///  - uid (cache rápido sin tener que decodificar el JWT)
class SecureSessionStore {
  SecureSessionStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _kIdToken = 'session.idToken';
  static const _kRefreshToken = 'session.refreshToken';
  static const _kUid = 'session.uid';

  final FlutterSecureStorage _storage;

  Future<void> saveSession({
    required String idToken,
    required String refreshToken,
    required String uid,
  }) async {
    await Future.wait([
      _storage.write(key: _kIdToken, value: idToken),
      _storage.write(key: _kRefreshToken, value: refreshToken),
      _storage.write(key: _kUid, value: uid),
    ]);
  }

  Future<void> updateIdToken(String idToken) =>
      _storage.write(key: _kIdToken, value: idToken);

  Future<String?> readIdToken() => _storage.read(key: _kIdToken);
  Future<String?> readRefreshToken() => _storage.read(key: _kRefreshToken);
  Future<String?> readUid() => _storage.read(key: _kUid);

  Future<bool> hasSession() async {
    final token = await _storage.read(key: _kRefreshToken);
    return token != null && token.isNotEmpty;
  }

  Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: _kIdToken),
      _storage.delete(key: _kRefreshToken),
      _storage.delete(key: _kUid),
    ]);
  }
}
