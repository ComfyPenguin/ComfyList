import 'package:comfy_list/shared/core/failures/failure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('mensajes por defecto en español', () {
    const messages = <Failure, String>{
      NetworkFailure(): 'No hay conexión. Inténtalo de nuevo.',
      TimeoutFailure(): 'La petición ha tardado demasiado.',
      ServerFailure(): 'Algo ha fallado en el servidor. Inténtalo más tarde.',
      AuthFailure(): 'No has podido autenticarte.',
      InvalidCredentialsFailure(): 'Correo o contraseña incorrectos.',
      EmailAlreadyInUseFailure(): 'Ese correo ya está registrado.',
      WeakPasswordFailure(): 'La contraseña es demasiado débil.',
      TooManyAttemptsFailure():
          'Demasiados intentos fallidos. Espera unos minutos e inténtalo de nuevo.',
      AccountDisabledFailure(): 'Esta cuenta está deshabilitada.',
      PasswordLoginDisabledFailure():
          'El acceso con correo y contraseña está desactivado.',
      GoogleSignInCancelledFailure():
          'Has cancelado el inicio de sesión con Google.',
      GoogleSignInFailure(): 'No se ha podido iniciar sesión con Google.',
      NotFoundFailure(): 'No se ha encontrado el recurso.',
      CacheFailure(): 'No se ha podido leer el almacén local.',
      UnknownFailure(): 'Ha ocurrido un error inesperado.',
    };

    messages.forEach((failure, message) {
      test('${failure.runtimeType} dice «$message»', () {
        expect(failure.message, message);
      });
    });
  });

  group('ValidationFailure es parametrizable', () {
    test('acepta un mensaje arbitrario en el constructor', () {
      const failure = ValidationFailure('El título es obligatorio.');
      expect(failure.message, 'El título es obligatorio.');
    });
  });
}
