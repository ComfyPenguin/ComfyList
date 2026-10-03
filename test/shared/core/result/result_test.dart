import 'package:comfy_list/shared/core/failures/failure.dart';
import 'package:comfy_list/shared/core/result/result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Result.fold', () {
    test('Ok.fold dispatcha a onOk con el valor', () {
      const result = Ok<int>(42);
      final folded = result.fold(
        onOk: (v) => 'ok=$v',
        onErr: (f) => 'err=${f.message}',
      );
      expect(folded, 'ok=42');
    });

    test('Err.fold dispatcha a onErr con el failure', () {
      const result = Err<int>(NetworkFailure());
      final folded = result.fold(
        onOk: (v) => 'ok=$v',
        onErr: (f) => 'err=${f.message}',
      );
      expect(folded, 'err=No hay conexión. Inténtalo de nuevo.');
    });

    test('fold con un valor String funciona sobre el genérico', () {
      const result = Ok<String>('hola');
      final folded = result.fold(
        onOk: (v) => v.length,
        onErr: (f) => -1,
      );
      expect(folded, 4);
    });
  });

  group('Result.isOk / isErr', () {
    test('Ok es isOk=true e isErr=false', () {
      const result = Ok<int>(1);
      expect(result.isOk, isTrue);
      expect(result.isErr, isFalse);
    });

    test('Err es isOk=false e isErr=true', () {
      const result = Err<int>(UnknownFailure());
      expect(result.isOk, isFalse);
      expect(result.isErr, isTrue);
    });

    test('Ok y Err son mutuamente excluyentes para el mismo tipo', () {
      const ok = Ok<int>(1);
      const err = Err<int>(UnknownFailure());
      expect(ok.isOk != ok.isErr, isTrue);
      expect(err.isOk != err.isErr, isTrue);
    });
  });

  group('Result pattern matching exhaustivo', () {
    test('switch sobre Ok/Err cubre todas las ramas', () {
      const Result<int> r = Ok(7);
      final out = switch (r) {
        Ok<int>(value: final v) => 'ok=$v',
        Err<int>(failure: final f) => 'err=${f.message}',
      };
      expect(out, 'ok=7');
    });

    test('switch sobre Err cae en la rama Err', () {
      const Result<int> r = Err(NetworkFailure());
      final out = switch (r) {
        Ok<int>(value: final v) => 'ok=$v',
        Err<int>(failure: final f) => 'err=${f.message}',
      };
      expect(out, 'err=No hay conexión. Inténtalo de nuevo.');
    });
  });
}
