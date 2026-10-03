import 'package:comfy_list/shared/data/remote/firestore_value_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('encodeFields + decodeFields round-trip', () {
    test('preserva String, int, bool, double, DateTime y null', () {
      final original = <String, dynamic>{
        'title': 'Comprar pan',
        'count': 3,
        'isDone': false,
        'rating': 4.5,
        'date': DateTime.utc(2026, 6, 30, 12, 0),
        'note': null,
      };

      final encoded = FirestoreValueCodec.encodeFields(original);
      final decoded = FirestoreValueCodec.decodeFields(encoded);

      expect(decoded['title'], 'Comprar pan');
      expect(decoded['count'], 3);
      expect(decoded['count'], isA<int>(),
          reason: 'int debe decodificarse como int (no double).');
      expect(decoded['isDone'], false);
      expect(decoded['rating'], 4.5);
      expect(decoded['rating'], isA<double>(),
          reason: 'double debe decodificarse como double.');
      expect(decoded['date'], DateTime.utc(2026, 6, 30, 12, 0).toLocal());
      expect(decoded['note'], isNull);
    });

    test('envuelve los valores en la clave "fields"', () {
      final out = FirestoreValueCodec.encodeFields({'a': 1});
      expect(out.containsKey('fields'), isTrue);
      final fields = out['fields'] as Map<String, dynamic>;
      expect(fields['a'], {'integerValue': '1'});
    });

    test('maneja un mapa vacío sin lanzar', () {
      final out = FirestoreValueCodec.encodeFields(const {});
      final decoded = FirestoreValueCodec.decodeFields(out);
      expect(decoded, isEmpty);
    });
  });

  group('idFromName', () {
    test('extrae el segmento final de un name de Firestore', () {
      const name = 'projects/p/databases/(default)/documents/users/uid/lists/abc';
      expect(FirestoreValueCodec.idFromName(name), 'abc');
    });

    test('devuelve el string completo si no hay separadores', () {
      expect(FirestoreValueCodec.idFromName('solo'), 'solo');
    });

    test('devuelve string vacío si el input es vacío', () {
      expect(FirestoreValueCodec.idFromName(''), '');
    });
  });

  group('encodeValue lanza en tipos no soportados', () {
    test('lanza ArgumentError con una List', () {
      expect(
        () => FirestoreValueCodec.encodeValue(<int>[1, 2, 3]),
        throwsArgumentError,
      );
    });

    test('lanza ArgumentError con un Map arbitrario', () {
      expect(
        () => FirestoreValueCodec.encodeValue({'a': 1}),
        throwsArgumentError,
      );
    });
  });

  group('decodeValue', () {
    test('devuelve null para nullValue', () {
      expect(FirestoreValueCodec.decodeValue({'nullValue': null}), isNull);
    });

    test('decodifica stringValue', () {
      expect(
        FirestoreValueCodec.decodeValue({'stringValue': 'hola'}),
        'hola',
      );
    });

    test('decodifica booleanValue', () {
      expect(
        FirestoreValueCodec.decodeValue({'booleanValue': true}),
        isTrue,
      );
    });

    test('decodifica integerValue como int', () {
      expect(
        FirestoreValueCodec.decodeValue({'integerValue': '42'}),
        42,
      );
    });

    test('decodifica doubleValue como double', () {
      expect(
        FirestoreValueCodec.decodeValue({'doubleValue': 3.14}),
        3.14,
      );
    });

    test('decodifica timestampValue como DateTime en hora local', () {
      final result = FirestoreValueCodec.decodeValue({
        'timestampValue': '2026-06-30T12:00:00Z',
      });
      expect(result, isA<DateTime>());
      expect((result as DateTime).isUtc, isFalse,
          reason: 'decodeValue convierte a hora local para formateo directo.');
      expect(result, DateTime.parse('2026-06-30T12:00:00Z').toLocal());
    });
  });
}
