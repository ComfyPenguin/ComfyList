/// Tipos de error sealed que cruzan las capas data → domain → presentation.
/// Mensajes orientados al usuario (en español de España, "tú").
sealed class Failure {
  const Failure(this.message);
  final String message;

  @override
  String toString() => '$runtimeType($message)';
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No hay conexión. Inténtalo de nuevo.']);
}

class TimeoutFailure extends Failure {
  const TimeoutFailure([super.message = 'La petición ha tardado demasiado.']);
}

class ServerFailure extends Failure {
  const ServerFailure([
    super.message = 'Algo ha fallado en el servidor. Inténtalo más tarde.',
  ]);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'No has podido autenticarte.']);
}

class InvalidCredentialsFailure extends AuthFailure {
  const InvalidCredentialsFailure()
      : super('Correo o contraseña incorrectos.');
}

class EmailAlreadyInUseFailure extends AuthFailure {
  const EmailAlreadyInUseFailure() : super('Ese correo ya está registrado.');
}

class WeakPasswordFailure extends AuthFailure {
  const WeakPasswordFailure() : super('La contraseña es demasiado débil.');
}

/// Firebase corta el grifo tras varios intentos fallidos: es su protección
/// contra la fuerza bruta, no un fallo de red.
class TooManyAttemptsFailure extends AuthFailure {
  const TooManyAttemptsFailure()
      : super('Demasiados intentos fallidos. Espera unos minutos e inténtalo de nuevo.');
}

/// Cuenta deshabilitada desde la consola de Firebase.
class AccountDisabledFailure extends AuthFailure {
  const AccountDisabledFailure()
      : super('Esta cuenta está deshabilitada.');
}

/// El proyecto tiene desactivado el acceso con correo y contraseña.
class PasswordLoginDisabledFailure extends AuthFailure {
  const PasswordLoginDisabledFailure()
      : super('El acceso con correo y contraseña está desactivado.');
}

/// El usuario cerró el popup nativo de Google sin completar el inicio de sesión.
/// No es un error real — la UI debería silenciarlo o mostrar mensaje neutro.
class GoogleSignInCancelledFailure extends AuthFailure {
  const GoogleSignInCancelledFailure()
      : super('Has cancelado el inicio de sesión con Google.');
}

/// Fallo del flujo nativo de Google (sin internet, configuración incorrecta,
/// Play Services no disponible, etc.) que no es cancelación del usuario.
class GoogleSignInFailure extends AuthFailure {
  const GoogleSignInFailure([
    super.message = 'No se ha podido iniciar sesión con Google.',
  ]);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'No se ha encontrado el recurso.']);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'No se ha podido leer el almacén local.']);
}

/// Lo descargado no es lo publicado: se descarta antes de instalarlo.
class IntegrityFailure extends Failure {
  const IntegrityFailure([
    super.message =
        'La descarga no coincide con el archivo publicado. Vuelve a intentarlo.',
  ]);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Ha ocurrido un error inesperado.']);
}
