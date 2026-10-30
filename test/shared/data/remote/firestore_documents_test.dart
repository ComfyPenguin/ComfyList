import 'package:comfy_list/shared/data/remote/firestore_documents.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/dio_mock.dart';

void main() {
  late MockDio dio;
  final doc = <String, dynamic>{'name': 'projects/p/documents/c/abc'};
  final body = <String, dynamic>{
    'fields': {
      'title': {'stringValue': 'Pan'},
    },
  };

  setUp(() => dio = MockDio());

  test('createDocument hace POST a la colección y devuelve el documento',
      () async {
    stubDioPost(dio, body: doc);

    final created = await dio.createDocument('https://x/c', body);

    expect(created, doc);
    verify(() => dio.post<Map<String, dynamic>>(
          'https://x/c',
          data: body,
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
        )).called(1);
  });

  group('patchDocument', () {
    test('con máscara manda updateMask.fieldPaths', () async {
      stubDioPatch(dio, body: doc);

      final patched = await dio.patchDocument(
        'https://x/c/abc',
        body,
        updateMask: ['title', 'updatedAt'],
      );

      expect(patched, doc);
      verify(() => dio.patch<Map<String, dynamic>>(
            'https://x/c/abc',
            data: body,
            queryParameters: {
              'updateMask.fieldPaths': ['title', 'updatedAt'],
            },
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).called(1);
    });

    test('sin máscara reescribe el documento entero, sin parámetros', () async {
      stubDioPatch(dio, body: doc);

      await dio.patchDocument('https://x/c/abc', body);

      final captured = verify(() => dio.patch<Map<String, dynamic>>(
            'https://x/c/abc',
            data: body,
            queryParameters: captureAny(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).captured;
      expect(captured.single, isNull);
    });
  });
}
