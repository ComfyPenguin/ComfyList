import 'package:comfy_list/features/todos/data/datasources/firestore_rest_remote.dart';
import 'package:comfy_list/shared/core/env/firebase_endpoints.dart';
import 'package:comfy_list/shared/data/remote/firestore_value_codec.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/dio_mock.dart';
import '../../../../helpers/test_helpers.dart';

class _MockDio extends MockDio {}

void main() {
  late _MockDio dio;
  late FirestoreRestRemote remote;

  setUp(() {
    dio = _MockDio();
    remote = FirestoreRestRemote(dio);
  });

  String expectedCollection(String uid, String listId) =>
      '${FirebaseEndpoints.firestoreBase}/users/$uid/todo_lists/$listId/todos';

  Map<String, dynamic> buildDocBody({
    required String name,
    required String title,
    String? description,
    bool isDone = false,
  }) {
    return <String, dynamic>{
      'name': name,
      'fields': FirestoreValueCodec.encodeFields(<String, dynamic>{
        'title': title,
        'description': ?description,
        'isDone': isDone,
        'createdAt': DateTime.utc(2026, 1, 1),
        'updatedAt': DateTime.utc(2026, 1, 1),
      })['fields'],
    };
  }

  group('FirestoreRestRemote', () {
    test('listTodos returns a parsed list', () async {
      final body = <String, dynamic>{
        'documents': [
          buildDocBody(
            name:
                'projects/p/databases/(default)/documents/users/u1/todo_lists/L1/todos/t1',
            title: 'Comprar pan',
          ),
        ],
      };
      stubDioGet(dio, body: body, withQueryParameters: true);

      final todos = await remote.listTodos(uid: 'u1', listId: 'L1');

      expect(todos, hasLength(1));
      expect(todos.first.id, 't1');
      expect(todos.first.title, 'Comprar pan');
      expect(todos.first.isDone, isFalse);
      verify(() => dio.get<Map<String, dynamic>>(
            any(),
            queryParameters: any(named: 'queryParameters'),
          )).called(1);
    });

    test('createTodo posts and decodes', () async {
      final body = buildDocBody(
        name:
            'projects/p/databases/(default)/documents/users/u1/todo_lists/L1/todos/t2',
        title: 'Comprar leche',
      );
      stubDioPost(dio, body: body);

      final created = await remote.createTodo(
        uid: 'u1',
        listId: 'L1',
        title: 'Comprar leche',
      );

      expect(created.id, 't2');
      expect(created.title, 'Comprar leche');
      verify(() => dio.post<Map<String, dynamic>>(
            expectedCollection('u1', 'L1'),
            data: any(named: 'data'),
          )).called(1);
    });

    test('updateTodo sends an updateMask with only the patched fields',
        () async {
      final body = buildDocBody(
        name:
            'projects/p/databases/(default)/documents/users/u1/todo_lists/L1/todos/t1',
        title: 'Comprar pan',
        isDone: true,
      );
      stubDioPatch(dio, body: body);

      await remote.updateTodo(
        uid: 'u1',
        listId: 'L1',
        id: 't1',
        isDone: true,
      );

      // Verificamos que la llamada de patch incluye el updateMask correcto.
      // Usamos `any()` para el path y matcher para queryParameters.
      verify(() => dio.patch<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
            queryParameters: any(
              named: 'queryParameters',
              that: predicate<Map<String, dynamic>>(
                (q) {
                  final mask = q['updateMask.fieldPaths'] as List<dynamic>?;
                  if (mask == null) return false;
                  final list = mask.cast<String>();
                  return list.contains('isDone') &&
                      list.contains('updatedAt') &&
                      !list.contains('title');
                },
              ),
            ),
          )).called(1);
    });

    test('deleteTodo calls the right URL', () async {
      stubDioDelete(dio);

      await remote.deleteTodo(uid: 'u1', listId: 'L1', id: 't1');

      verify(() => dio.delete<void>('${expectedCollection('u1', 'L1')}/t1'))
          .called(1);
    });

    test('restoreTodo vuelve a escribir el documento con su mismo id',
        () async {
      final body = buildDocBody(
        name:
            'projects/p/databases/(default)/documents/users/u1/todo_lists/L1/todos/t1',
        title: 'Comprar pan',
      );
      stubDioPatch(dio, body: body);

      final restored = await remote.restoreTodo(
        uid: 'u1',
        listId: 'L1',
        todo: buildTodo(id: 't1'),
      );

      expect(restored.id, 't1');
      expect(restored.title, 'Comprar pan');
      verify(() => dio.patch<Map<String, dynamic>>(
            '${expectedCollection('u1', 'L1')}/t1',
            data: any(named: 'data'),
          )).called(1);
    });
  });
}
