import '../../../../shared/core/result/result.dart';
import '../entities/auth_user.dart';

/// Contrato de auth — la implementación REST vive en `data/`.
abstract class AuthRepository {
  /// Devuelve el usuario actual si hay refreshToken válido en el almacén
  /// seguro; refresca y obtiene el perfil con `accounts:lookup`.
  Future<Result<AuthUser?>> currentUser();

  Future<Result<AuthUser>> signIn({
    required String email,
    required String password,
  });

  Future<Result<AuthUser>> signUp({
    required String email,
    required String password,
  });

  /// Inicia sesión con Google. Orquesta el flujo nativo (Google Sign-In SDK)
  /// y el intercambio del token contra Firebase via `accounts:signInWithIdp`.
  /// Si el usuario no existe en Firebase Auth, lo crea de forma transparente.
  Future<Result<AuthUser>> signInWithGoogle();

  /// Envía un correo con enlace de restablecimiento de contraseña.
  ///
  /// Por privacidad (evitar enumeración de cuentas) trata "email no registrado"
  /// como éxito silencioso — la UI debe mostrar siempre el mismo mensaje
  /// genérico independientemente de si el correo existe o no.
  Future<Result<void>> sendPasswordResetEmail({required String email});

  /// Manda (o reenvía) el correo de verificación a la sesión actual. El
  /// `signUp` ya lo hace solo; esto es para el botón de reenviar.
  Future<Result<void>> sendEmailVerification();

  /// Cierra la sesión: borra los tokens locales y, antes de eso, pide al
  /// servidor que revoque los emitidos hasta ahora (best-effort — la salida no
  /// depende de que haya red).
  Future<void> signOut();
}
