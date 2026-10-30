import 'package:comfy_list/shared/data/remote/firestore_patch.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.utc(2026, 6, 1, 9);

  Map<String, dynamic> fieldsOf(Map<String, dynamic> body) =>
      body['fields'] as Map<String, dynamic>;

  test('un parche vacío solo toca updatedAt', () {
    final (body, mask) = FirestorePatch().build(updatedAt: now);

    expect(mask, ['updatedAt']);
    expect(fieldsOf(body).keys, ['updatedAt']);
    expect(fieldsOf(body)['updatedAt'], {
      'timestampValue': '2026-06-01T09:00:00.000Z',
    });
  });

  test('set manda el campo aunque el valor sea null (lo borra)', () {
    final patch = FirestorePatch()
      ..set('title', 'Pan')
      ..set('description', null);

    final (body, mask) = patch.build(updatedAt: now);

    expect(mask, ['title', 'description', 'updatedAt']);
    expect(fieldsOf(body)['title'], {'stringValue': 'Pan'});
    expect(fieldsOf(body)['description'], {'nullValue': null});
  });

  test('setIfNotNull se salta lo que no se cambia', () {
    final patch = FirestorePatch()
      ..setIfNotNull('title', null)
      ..setIfNotNull('isDone', true);

    final (body, mask) = patch.build(updatedAt: now);

    expect(mask, ['isDone', 'updatedAt']);
    expect(fieldsOf(body).containsKey('title'), isFalse);
    expect(fieldsOf(body)['isDone'], {'booleanValue': true});
  });

  group('setOrClear', () {
    test('con un valor lo manda', () {
      final patch = FirestorePatch()
        ..setOrClear('description', 'Nota', clear: false);

      final (body, mask) = patch.build(updatedAt: now);

      expect(mask, ['description', 'updatedAt']);
      expect(fieldsOf(body)['description'], {'stringValue': 'Nota'});
    });

    test('con clear lo borra aunque haya valor', () {
      final patch = FirestorePatch()
        ..setOrClear('description', 'Nota', clear: true);

      final (body, mask) = patch.build(updatedAt: now);

      expect(mask, ['description', 'updatedAt']);
      expect(fieldsOf(body)['description'], {'nullValue': null});
    });

    test('sin valor y sin clear no lo toca', () {
      final patch = FirestorePatch()
        ..setOrClear('description', null, clear: false);

      final (_, mask) = patch.build(updatedAt: now);

      expect(mask, ['updatedAt']);
    });
  });

  test('la máscara conserva el orden en que se anotaron los campos', () {
    final patch = FirestorePatch()
      ..set('b', 1)
      ..set('a', 2)
      ..set('c', 3);

    final (_, mask) = patch.build(updatedAt: now);

    expect(mask, ['b', 'a', 'c', 'updatedAt']);
  });
}
