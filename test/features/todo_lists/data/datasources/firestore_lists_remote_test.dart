import 'package:comfy_list/features/todo_lists/data/datasources/firestore_lists_remote.dart';
import 'package:comfy_list/shared/data/remote/firestore_value_codec.dart';
import 'package:comfy_list/shared/core/env/firebase_endpoints.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/dio_mock.dart';
import '../../../../helpers/test_helpers.dart';

class _MockDio extends MockDio {}

void main() {
  late _MockDio dio;
  late FirestoreListsRemote remote;

  setUp(() {
    dio = _MockDio();
    remote = FirestoreListsRemote(dio);
  });

  String expectedCollection(String uid) =>
      '${FirebaseEndpoints.firestoreBase}/users/$uid/todo_lists';

  Map<String, dynamic> buildDocBody({
    required String name,
    required String listName,
    String iconKey = 'cart',
  }) {
    return <String, dynamic>{
      'name': name,
      'fields': FirestoreValueCodec.encodeFields(<String, dynamic>{
        'name': listName,
        'iconKey': iconKey,
        'createdAt': DateTime.utc(2026, 1, 1),
        'updatedAt': DateTime.utc(2026, 1, 2),
      })['fields'],
    };
  }

  group('FirestoreListsRemote', () {
    test('listLists decodes documents to entities', () async {
      final body = <String, dynamic>{
        'documents': [
          buildDocBody(
            name:
                'projects/p/databases/(default)/documents/users/u1/todo_lists/L1',
            listName: 'Compras',
          ),
        ],
      };
      stubDioGet(dio, body: body, withQueryParameters: true);

      final lists = await remote.listLists('u1');

      expect(lists, hasLength(1));
      expect(lists.first.id, 'L1');
      expect(lists.first.name, 'Compras');
      expect(lists.first.iconKey, 'cart');
      verify(() => dio.get<Map<String, dynamic>>(
            any(),
            queryParameters: any(named: 'queryParameters'),
          )).called(1);
    });

    test('listLists returns an empty list when no documents', () async {
      stubDioGet(
        dio,
        body: <String, dynamic>{'documents': <dynamic>[]},
        withQueryParameters: true,
      );

      final lists = await remote.listLists('u1');

      expect(lists, isEmpty);
    });

    test('createList posts to the collection and decodes the response',
        () async {
      final body = buildDocBody(
        name: 'projects/p/databases/(default)/documents/users/u1/todo_lists/L2',
        listName: 'Trabajo',
        iconKey: 'work',
      );
      stubDioPost(dio, body: body);

      final created = await remote.createList(
        uid: 'u1',
        name: 'Trabajo',
        iconKey: 'work',
      );

      expect(created.id, 'L2');
      expect(created.name, 'Trabajo');
      expect(created.iconKey, 'work');
      // Verify that the post was called with the collection path
      verify(() => dio.post<Map<String, dynamic>>(
            expectedCollection('u1'),
            data: any(named: 'data'),
          )).called(1);
    });

    test('createList fecha el documento con el reloj que se le da', () async {
      final fixed = DateTime(2026, 6, 1, 9);
      remote = FirestoreListsRemote(dio, now: () => fixed);
      stubDioPost(
        dio,
        body: buildDocBody(
          name: 'projects/p/databases/(default)/documents/users/u1/todo_lists/L2',
          listName: 'Trabajo',
        ),
      );

      await remote.createList(uid: 'u1', name: 'Trabajo', iconKey: 'work');

      final sent = verify(() => dio.post<Map<String, dynamic>>(
            any(),
            data: captureAny(named: 'data'),
          )).captured.single as Map<String, dynamic>;
      final fields = (sent['fields'] as Map<String, dynamic>);
      final expected = {'timestampValue': fixed.toUtc().toIso8601String()};
      expect(fields['createdAt'], expected);
      expect(fields['updatedAt'], expected);
    });

    const root = 'projects/comfy-list/databases/(default)/documents';

    test('deleteListWithTodos borra las tareas y la lista en un commit',
        () async {
      stubDioCommit(dio);

      await remote.deleteListWithTodos(
        uid: 'u1',
        id: 'L1',
        todoIds: const ['t1', 't2'],
      );

      final writes = sentCommits(dio).single['writes'] as List;
      expect(writes, [
        {'delete': '$root/users/u1/todo_lists/L1/todos/t1'},
        {'delete': '$root/users/u1/todo_lists/L1/todos/t2'},
        // La lista va la última.
        {'delete': '$root/users/u1/todo_lists/L1'},
      ]);
    });

    test('deleteListWithTodos parte en tandas de 500 sin cambiar el orden',
        () async {
      stubDioCommit(dio);
      final ids = [for (var i = 0; i < 600; i++) 't$i'];

      await remote.deleteListWithTodos(uid: 'u1', id: 'L1', todoIds: ids);

      final commits = sentCommits(dio);
      expect(commits, hasLength(2));
      expect((commits.first['writes'] as List), hasLength(500));
      final last = (commits.last['writes'] as List);
      expect(last, hasLength(101));
      expect(last.last, {'delete': '$root/users/u1/todo_lists/L1'});
    });

    test('restoreListWithTodos escribe la lista y sus tareas en un commit',
        () async {
      stubDioCommit(dio);

      await remote.restoreListWithTodos(
        uid: 'u1',
        list: buildTodoList(id: 'L1', name: 'Compras'),
        todos: [buildTodo(id: 't1', title: 'Pan')],
      );

      final writes = sentCommits(dio).single['writes'] as List;
      expect(writes, hasLength(2));
      final listWrite = (writes[0] as Map)['update'] as Map<String, dynamic>;
      expect(listWrite['name'], '$root/users/u1/todo_lists/L1');
      expect(
        (listWrite['fields'] as Map)['name'],
        {'stringValue': 'Compras'},
      );
      final todoWrite = (writes[1] as Map)['update'] as Map<String, dynamic>;
      expect(todoWrite['name'], '$root/users/u1/todo_lists/L1/todos/t1');
      expect((todoWrite['fields'] as Map)['title'], {'stringValue': 'Pan'});
    });
  });
}
