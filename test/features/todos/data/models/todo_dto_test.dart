import 'package:comfy_list/features/todos/data/models/todo_dto.dart';
import 'package:comfy_list/shared/data/remote/firestore_value_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TodoDto', () {
    test('fromDocument decodes a complete document', () {
      final raw = <String, dynamic>{
        'name': 'projects/p/databases/(default)/documents/users/u1/todo_lists/L1/todos/t1',
        'fields': FirestoreValueCodec.encodeFields(<String, dynamic>{
          'title': 'Comprar pan',
          'description': 'En la esquina',
          'isDone': false,
          'createdAt': DateTime.utc(2026, 1, 1, 12),
          'updatedAt': DateTime.utc(2026, 1, 2, 12),
        })['fields'],
      };

      final todo = TodoDto.fromDocument(raw);

      expect(todo.id, 't1');
      expect(todo.title, 'Comprar pan');
      expect(todo.description, 'En la esquina');
      expect(todo.isDone, isFalse);
      expect(todo.createdAt.toUtc(), DateTime.utc(2026, 1, 1, 12));
      expect(todo.updatedAt.toUtc(), DateTime.utc(2026, 1, 2, 12));
    });

    test('toCreateBody omits description when null', () {
      final t = DateTime.utc(2026, 6, 1, 9);
      final body = TodoDto.toCreateBody(
        title: 'Comprar pan',
        now: t,
      );

      final decoded = FirestoreValueCodec.decodeFields(body);
      expect(decoded['title'], 'Comprar pan');
      // El collection-if de Dart 'description: ?description' omite el campo
      // cuando es null — verificamos que no aparece en el body codificado.
      expect(decoded.containsKey('description'), isFalse);
      expect(decoded['isDone'], isFalse);
    });

    test('toCreateBody with description includes it', () {
      final t = DateTime.utc(2026, 6, 1, 9);
      final body = TodoDto.toCreateBody(
        title: 'Comprar pan',
        description: 'En la esquina',
        now: t,
      );

      final decoded = FirestoreValueCodec.decodeFields(body);
      expect(decoded['description'], 'En la esquina');
    });

    test('toPatchBody with clearDescription includes mask with nullValue',
        () {
      final t = DateTime.utc(2026, 6, 1, 9);
      final (body, mask) = TodoDto.toPatchBody(
        clearDescription: true,
        now: t,
      );

      expect(mask, contains('description'));
      expect(mask, contains('updatedAt'));

      final encodedFields = body['fields'] as Map<String, dynamic>;
      expect(encodedFields['description'], <String, dynamic>{
        'nullValue': null,
      });
    });

    test('toPatchBody with only isDone includes isDone in mask', () {
      final t = DateTime.utc(2026, 6, 1, 9);
      final (body, mask) = TodoDto.toPatchBody(
        isDone: true,
        now: t,
      );

      expect(mask, contains('isDone'));
      expect(mask, isNot(contains('title')));
      expect(mask, isNot(contains('description')));
      expect(mask, contains('updatedAt'));

      final decoded = FirestoreValueCodec.decodeFields(body);
      expect(decoded['isDone'], isTrue);
    });
  });
}
