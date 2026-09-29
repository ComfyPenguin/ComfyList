import 'dart:convert';

import 'package:comfy_list/features/trash/data/datasources/firestore_trash_remote.dart';
import 'package:comfy_list/features/trash/domain/entities/trash_entry.dart';
import 'package:comfy_list/shared/core/env/firebase_endpoints.dart';
import 'package:comfy_list/shared/data/remote/firestore_value_codec.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/dio_mock.dart';

class _MockDio extends MockDio {}

void main() {
  late _MockDio dio;
  late FirestoreTrashRemote remote;

  setUp(() {
    dio = _MockDio();
    remote = FirestoreTrashRemote(dio);
  });

  String collection(String uid) =>
      '${FirebaseEndpoints.firestoreBase}/users/$uid/trash';

  Map<String, dynamic> buildDocBody({
    required String id,
    TrashKind kind = TrashKind.todo,
    String? parentId,
    String label = 'Comprar pan',
    Map<String, dynamic> payload = const {'id': 't1', 'title': 'Comprar pan'},
  }) {
    return <String, dynamic>{
      'name':
          'projects/p/databases/(default)/documents/users/u1/trash/$id',
      'fields': FirestoreValueCodec.encodeFields(<String, dynamic>{
        'groupId': 'g1',
        'kind': kind.value,
        'itemId': 't1',
        'parentId': ?parentId,
        'label': label,
        'payload': jsonEncode(payload),
        'deletedAt': DateTime.utc(2026, 6, 1, 9),
      })['fields'],
    };
  }

  group('FirestoreTrashRemote', () {
    test('listEntries id del nombre y saca el payload del texto', () async {
      stubDioGet(dio, body: <String, dynamic>{
        'documents': [
          buildDocBody(id: 'd1', parentId: 'L1', label: 'Comprar pan'),
        ],
      });

      final entries = await remote.listEntries('u1');

      expect(entries, hasLength(1));
      final entry = entries.single;
      expect(entry.id, 'd1');
      expect(entry.uid, 'u1');
      expect(entry.groupId, 'g1');
      expect(entry.kind, TrashKind.todo);
      expect(entry.itemId, 't1');
      expect(entry.parentId, 'L1');
      expect(entry.label, 'Comprar pan');
      expect(entry.payload, {'id': 't1', 'title': 'Comprar pan'});
      verify(() => dio.get<Map<String, dynamic>>(
            collection('u1'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).called(1);
    });

    test('un payload que no es JSON no rompe la lectura', () async {
      final body = buildDocBody(id: 'd1');
      (body['fields'] as Map<String, dynamic>)['payload'] = {
        'stringValue': 'no soy json',
      };
      stubDioGet(dio, body: <String, dynamic>{'documents': [body]});

      final entries = await remote.listEntries('u1');

      expect(entries.single.payload, isEmpty);
    });

    test('createEntry envía el payload como texto y omite el padre nulo',
        () async {
      stubDioPost(dio, body: buildDocBody(id: 'd2'));

      final created = await remote.createEntry(
        uid: 'u1',
        groupId: 'g1',
        item: const TrashItem(
          kind: TrashKind.todo,
          itemId: 't1',
          label: 'Comprar pan',
          payload: {'id': 't1', 'title': 'Comprar pan'},
        ),
        deletedAt: DateTime.utc(2026, 6, 1, 9),
      );

      expect(created.id, 'd2');
      final sent = verify(() => dio.post<Map<String, dynamic>>(
            collection('u1'),
            data: captureAny(named: 'data'),
          )).captured.single as Map<String, dynamic>;
      final fields = sent['fields'] as Map<String, dynamic>;
      expect(
        (fields['payload'] as Map<String, dynamic>)['stringValue'],
        jsonEncode({'id': 't1', 'title': 'Comprar pan'}),
      );
      expect(fields.containsKey('parentId'), isFalse);
      expect(
        (fields['deletedAt'] as Map<String, dynamic>)['timestampValue'],
        '2026-06-01T09:00:00.000Z',
      );
    });

    test('deleteEntry llama a la URL del documento', () async {
      stubDioDelete(dio);

      await remote.deleteEntry(uid: 'u1', id: 'd1');

      verify(() => dio.delete<void>('${collection('u1')}/d1')).called(1);
    });
  });
}
