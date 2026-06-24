import 'package:comfy_list/shared/data/remote/firestore_value_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('encodeFields', () {
    test('codifica string, bool, int y datetime', () {
      final ts = DateTime.utc(2026, 1, 1, 12, 30);
      final encoded = FirestoreValueCodec.encodeFields({
        'title': 'Comprar pan',
        'isDone': false,
        'count': 3,
        'createdAt': ts,
      });

      expect(encoded['fields']['title'], {'stringValue': 'Comprar pan'});
      expect(encoded['fields']['isDone'], {'booleanValue': false});
      expect(encoded['fields']['count'], {'integerValue': '3'});
      expect(
        encoded['fields']['createdAt'],
        {'timestampValue': '2026-01-01T12:30:00.000Z'},
      );
    });

    test('null se codifica como nullValue', () {
      final encoded = FirestoreValueCodec.encodeValue(null);
      expect(encoded, {'nullValue': null});
    });

    test('lanza ArgumentError con tipos no soportados', () {
      expect(
        () => FirestoreValueCodec.encodeValue([1, 2, 3]),
        throwsArgumentError,
      );
    });
  });

  group('decodeFields', () {
    test('decodifica un documento típico de TODO', () {
      final raw = {
        'name': 'projects/comfy-list/databases/(default)/documents/users/u1/todos/t1',
        'fields': {
          'title': {'stringValue': 'Comprar pan'},
          'isDone': {'booleanValue': true},
          'createdAt': {'timestampValue': '2026-01-01T12:30:00.000Z'},
          'description': {'nullValue': null},
        },
      };
      final decoded = FirestoreValueCodec.decodeFields(raw);
      expect(decoded['title'], 'Comprar pan');
      expect(decoded['isDone'], true);
      // El codec devuelve DateTime en hora local para que DateFormat.format
      // muestre la "hora del usuario" sin conversión manual. El momento
      // absoluto se preserva (ver assertion siguiente).
      final createdAt = decoded['createdAt'] as DateTime;
      expect(createdAt.isUtc, isFalse);
      expect(createdAt.toUtc(), DateTime.utc(2026, 1, 1, 12, 30));
      expect(decoded['description'], isNull);
    });

    test('mapa vacío si no hay fields', () {
      expect(FirestoreValueCodec.decodeFields(null), isEmpty);
      expect(FirestoreValueCodec.decodeFields({}), isEmpty);
    });
  });

  test('idFromName extrae el último segmento', () {
    expect(
      FirestoreValueCodec.idFromName(
        'projects/comfy-list/databases/(default)/documents/users/u1/todos/abc123',
      ),
      'abc123',
    );
  });
}
