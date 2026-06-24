import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persistencia de la preferencia "recordar correo" del login.
///
/// El correo no es un secreto, pero reutilizamos el mismo backend cifrado
/// que usa [SecureSessionStore] para mantener una única superficie de
/// almacenamiento local del feature de auth.
class LoginPreferencesStore {
  LoginPreferencesStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _kLastEmail = 'login.lastEmail';
  static const _kRememberEmail = 'login.rememberEmail';

  final FlutterSecureStorage _storage;

  Future<String?> readLastEmail() => _storage.read(key: _kLastEmail);

  Future<bool> readRememberEmail() async {
    final value = await _storage.read(key: _kRememberEmail);
    return value == 'true';
  }

  Future<void> saveRememberedEmail(String email) async {
    await Future.wait([
      _storage.write(key: _kLastEmail, value: email),
      _storage.write(key: _kRememberEmail, value: 'true'),
    ]);
  }

  /// Olvida el correo pero conserva la preferencia explícita en `false`
  /// para que la pantalla pueda restaurar el estado del checkbox.
  Future<void> clearRememberedEmail() async {
    await Future.wait([
      _storage.delete(key: _kLastEmail),
      _storage.write(key: _kRememberEmail, value: 'false'),
    ]);
  }
}
