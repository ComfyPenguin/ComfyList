import 'package:comfy_list/shared/data/remote/firestore_pages.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/dio_mock.dart';

void main() {
  test('sigue el nextPageToken hasta leer la colección entera', () async {
    final dio = MockDio();
    final tokens = <Object?>[];
    when(() => dio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        )).thenAnswer((invocation) async {
      final query =
          invocation.namedArguments[#queryParameters] as Map<String, dynamic>;
      tokens.add(query['pageToken']);
      final first = query['pageToken'] == null;
      return Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(),
        data: {
          'documents': [
            {'name': first ? 'a' : 'b'},
          ],
          if (first) 'nextPageToken': 'p2',
        },
      );
    });

    final docs = await dio.getAllDocuments('https://example.test/col');

    expect(docs.map((d) => d['name']), ['a', 'b']);
    expect(tokens, [null, 'p2']);
  });
}
