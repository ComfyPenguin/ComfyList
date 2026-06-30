import 'package:comfy_list/shared/core/failures/failure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('mensajes por defecto en español', () {
    test('NetworkFailure expone el mensaje de red', () {
      expect(const NetworkFailure().message, 'No hay conexión. Inténtalo de nuevo.');
    });

    test('TimeoutFailure expone el mensaje de timeout', () {
      expect(
        const TimeoutFailure().message,
        'La petición ha tardado demasiado.',
      );
    });

    test('ServerFailure expone el mensaje de servidor', () {
      expect(
        const ServerFailure().message,
        'Algo ha fallado en el servidor. Inténtalo más tarde.',
      );
    });

    test('AuthFailure expone el mensaje genérico de auth', () {
      expect(const AuthFailure().message, 'No has podido autenticarte.');
    });

    test('InvalidCredentialsFailure tiene mensaje específico', () {
      expect(
        const InvalidCredentialsFailure().message,
        'Correo o contraseña incorrectos.',
      );
    });

    test('EmailAlreadyInUseFailure tiene mensaje específico', () {
      expect(
        const EmailAlreadyInUseFailure().message,
        'Ese correo ya está registrado.',
      );
    });

    test('WeakPasswordFailure tiene mensaje específico', () {
      expect(
        const WeakPasswordFailure().message,
        'La contraseña es demasiado débil.',
      );
    });

    test('GoogleSignInCancelledFailure tiene mensaje específico', () {
      expect(
        const GoogleSignInCancelledFailure().message,
        'Has cancelado el inicio de sesión con Google.',
      );
    });

    test('GoogleSignInFailure tiene mensaje por defecto', () {
      expect(
        const GoogleSignInFailure().message,
        'No se ha podido iniciar sesión con Google.',
      );
    });

    test('NotFoundFailure expone el mensaje de recurso ausente', () {
      expect(
        const NotFoundFailure().message,
        'No se ha encontrado el recurso.',
      );
    });

    test('CacheFailure expone el mensaje de caché', () {
      expect(
        const CacheFailure().message,
        'No se ha podido leer el almacén local.',
      );
    });

    test('UnknownFailure expone el mensaje genérico', () {
      expect(
        const UnknownFailure().message,
        'Ha ocurrido un error inesperado.',
      );
    });
  });

  group('ValidationFailure es parametrizable', () {
    test('acepta un mensaje arbitrario en el constructor', () {
      const failure = ValidationFailure('El título es obligatorio.');
      expect(failure.message, 'El título es obligatorio.');
    });
  });

  group('subtipos de AuthFailure son distinguibles', () {
    test('cada subtipo es instanceof AuthFailure y runtimeType propio', () {
      const failures = <AuthFailure>[
        InvalidCredentialsFailure(),
        EmailAlreadyInUseFailure(),
        WeakPasswordFailure(),
        GoogleSignInCancelledFailure(),
        GoogleSignInFailure(),
      ];
      final runtimes = failures.map((f) => f.runtimeType).toSet();
      expect(runtimes.length, failures.length,
          reason: 'Cada subtipo debe tener runtimeType único.');
      for (final f in failures) {
        expect(f, isA<AuthFailure>(),
            reason: '${f.runtimeType} debe extender AuthFailure.');
        expect(f.message, isNotEmpty,
            reason: '${f.runtimeType} debe exponer un mensaje al usuario.');
      }
    });

    test('un switch exhaustivo cubre las 5 ramas (compilación)', () {
      const AuthFailure f = InvalidCredentialsFailure();
      final label = switch (f) {
        InvalidCredentialsFailure() => 'invalid',
        EmailAlreadyInUseFailure() => 'exists',
        WeakPasswordFailure() => 'weak',
        GoogleSignInCancelledFailure() => 'cancelled',
        GoogleSignInFailure() => 'google_error',
        AuthFailure() => 'generic',
      };
      expect(label, 'invalid');
    });
  });

  group('toString', () {
    test('incluye runtimeType y message', () {
      const failure = ServerFailure('Error 500');
      expect(failure.toString(), 'ServerFailure(Error 500)');
    });

    test('usa la jerarquía para subtipos', () {
      const failure = InvalidCredentialsFailure();
      expect(failure.toString(),
          'InvalidCredentialsFailure(Correo o contraseña incorrectos.)');
    });
  });
}
