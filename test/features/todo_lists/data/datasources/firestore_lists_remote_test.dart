import 'package:comfy_list/features/todo_lists/data/datasources/firestore_lists_remote.dart';
import 'package:comfy_list/shared/data/remote/firestore_value_codec.dart';
import 'package:comfy_list/shared/core/env/firebase_endpoints.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/dio_mock.dart';

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
      stubDioGet(dio, body: body);

      final lists = await remote.listLists('u1');

      expect(lists, hasLength(1));
      expect(lists.first.id, 'L1');
      expect(lists.first.name, 'Compras');
      expect(lists.first.iconKey, 'cart');
      verify(() => dio.get<Map<String, dynamic>>(
            any(),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).called(1);
    });

    test('listLists returns an empty list when no documents', () async {
      stubDioGet(dio, body: <String, dynamic>{'documents': <dynamic>[]});

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

    test('deleteList calls the right URL', () async {
      stubDioDelete(dio);

      await remote.deleteList(uid: 'u1', id: 'L1');

      verify(() => dio.delete<void>('${expectedCollection('u1')}/L1'))
          .called(1);
    });
  });
}
