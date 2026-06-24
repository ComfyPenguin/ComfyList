import 'package:comfy_list/features/todos/data/models/todo_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TodoDto.fromDocument', () {
    test('parsea un documento completo', () {
      final raw = {
        'name': 'projects/x/databases/(default)/documents/users/u/todos/abc',
        'fields': {
          'title': {'stringValue': 'Comprar pan'},
          'description': {'stringValue': 'Integral'},
          'isDone': {'booleanValue': false},
          'createdAt': {'timestampValue': '2026-01-01T00:00:00.000Z'},
          'updatedAt': {'timestampValue': '2026-01-02T00:00:00.000Z'},
        },
      };
      final todo = TodoDto.fromDocument(raw);
      expect(todo.id, 'abc');
      expect(todo.title, 'Comprar pan');
      expect(todo.description, 'Integral');
      expect(todo.isDone, false);
      // El codec entrega DateTimes en local; comparamos el momento absoluto.
      expect(todo.createdAt.toUtc(), DateTime.utc(2026, 1, 1));
      expect(todo.updatedAt.toUtc(), DateTime.utc(2026, 1, 2));
    });

    test('rellena defaults cuando faltan campos', () {
      final raw = {
        'name': 'projects/x/databases/(default)/documents/users/u/todos/x',
        'fields': {
          'title': {'stringValue': 'Sin metadatos'},
        },
      };
      final todo = TodoDto.fromDocument(raw);
      expect(todo.title, 'Sin metadatos');
      expect(todo.isDone, false);
      expect(todo.description, isNull);
      expect(todo.createdAt.isUtc, isFalse);
    });
  });

  group('TodoDto.toCreateBody', () {
    test('arma fields con createdAt/updatedAt y omite description si null', () {
      final now = DateTime.utc(2026, 5, 9, 10);
      final body = TodoDto.toCreateBody(title: 'Pasear', now: now);
      final fields = body['fields'] as Map<String, dynamic>;
      expect(fields['title'], {'stringValue': 'Pasear'});
      expect(fields['isDone'], {'booleanValue': false});
      expect(fields.containsKey('description'), isFalse);
      expect(fields['createdAt'], {'timestampValue': '2026-05-09T10:00:00.000Z'});
      expect(fields['updatedAt'], {'timestampValue': '2026-05-09T10:00:00.000Z'});
    });
  });

  group('TodoDto.toPatchBody', () {
    test('genera mask coherente con los campos enviados', () {
      final now = DateTime.utc(2026, 5, 9);
      final (body, mask) = TodoDto.toPatchBody(
        title: 'Nuevo título',
        isDone: true,
        now: now,
      );
      expect(mask, containsAll(['title', 'isDone', 'updatedAt']));
      final fields = body['fields'] as Map<String, dynamic>;
      expect(fields['title'], {'stringValue': 'Nuevo título'});
      expect(fields['isDone'], {'booleanValue': true});
    });

    test('clearDescription envía nullValue y entra en la mask', () {
      final now = DateTime.utc(2026, 5, 9);
      final (body, mask) = TodoDto.toPatchBody(
        clearDescription: true,
        now: now,
      );
      expect(mask, contains('description'));
      final fields = body['fields'] as Map<String, dynamic>;
      expect(fields['description'], {'nullValue': null});
    });
  });
}
