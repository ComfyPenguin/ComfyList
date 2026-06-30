import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';

/// Hand-declared — sin `build_runner`, sin codegen. Usar solo en tests de
/// datasource (capa que habla HTTP con Firestore o Identity Toolkit).
/// En tests de repository, mockear directamente el `*Remote`.
class MockDio extends Mock implements Dio {}

/// Stubs `dio.get` para devolver un 200 con el body JSON dado. El path
/// matcher es `any()`; para aserciones sobre la URL usar `verify` con
/// `anyThat: (o) => o.path.contains('signIn')`.
void stubDioGet(
  MockDio dio, {
  String path = '',
  required Map<String, dynamic> body,
  int statusCode = 200,
}) {
  when(() => dio.get<Map<String, dynamic>>(
        any(),
        options: any(named: 'options'),
        cancelToken: any(named: 'cancelToken'),
      )).thenAnswer(
    (_) async => Response<Map<String, dynamic>>(
      requestOptions: RequestOptions(path: path),
      data: body,
      statusCode: statusCode,
    ),
  );
}

void stubDioPost(
  MockDio dio, {
  String path = '',
  required Map<String, dynamic> body,
  int statusCode = 200,
}) {
  when(() => dio.post<Map<String, dynamic>>(
        any(),
        data: any(named: 'data'),
        options: any(named: 'options'),
        cancelToken: any(named: 'cancelToken'),
      )).thenAnswer(
    (_) async => Response<Map<String, dynamic>>(
      requestOptions: RequestOptions(path: path),
      data: body,
      statusCode: statusCode,
    ),
  );
}

void stubDioPatch(
  MockDio dio, {
  String path = '',
  required Map<String, dynamic> body,
  int statusCode = 200,
}) {
  when(() => dio.patch<Map<String, dynamic>>(
        any(),
        data: any(named: 'data'),
        queryParameters: any(named: 'queryParameters'),
        options: any(named: 'options'),
        cancelToken: any(named: 'cancelToken'),
      )).thenAnswer(
    (_) async => Response<Map<String, dynamic>>(
      requestOptions: RequestOptions(path: path),
      data: body,
      statusCode: statusCode,
    ),
  );
}

void stubDioDelete(
  MockDio dio, {
  String path = '',
  int statusCode = 200,
  Map<String, dynamic>? body,
}) {
  when(() => dio.delete<void>(any())).thenAnswer(
    (_) async => Response<dynamic>(
      requestOptions: RequestOptions(path: path),
      data: body,
      statusCode: statusCode,
    ),
  );
}

/// Atajo: stub TODOS los verbos (get/post/patch/delete) con el mismo body.
void stubDioSuccess(
  MockDio dio, {
  String path = '',
  required Map<String, dynamic> body,
  int statusCode = 200,
}) {
  stubDioGet(dio, path: path, body: body, statusCode: statusCode);
  stubDioPost(dio, path: path, body: body, statusCode: statusCode);
  stubDioPatch(dio, path: path, body: body, statusCode: statusCode);
  stubDioDelete(dio, path: path, statusCode: statusCode, body: body);
}

/// Stubs todos los verbos para lanzar una `DioException` con el tipo dado.
/// Útil para tests de mapeo de errores (NetworkFailure, TimeoutFailure...).
void stubDioError(
  MockDio dio, {
  required DioExceptionType type,
  int? statusCode,
  Map<String, dynamic>? body,
  String message = 'dio error stub',
}) {
  final response = statusCode != null
      ? Response<dynamic>(
          requestOptions: RequestOptions(path: ''),
          data: body,
          statusCode: statusCode,
        )
      : null;

  final exception = DioException(
    requestOptions: RequestOptions(path: ''),
    type: type,
    response: response,
    message: message,
  );

  when(() => dio.get<Map<String, dynamic>>(
        any(),
        options: any(named: 'options'),
        cancelToken: any(named: 'cancelToken'),
      )).thenThrow(exception);
  when(() => dio.post<Map<String, dynamic>>(
        any(),
        data: any(named: 'data'),
        options: any(named: 'options'),
        cancelToken: any(named: 'cancelToken'),
      )).thenThrow(exception);
  when(() => dio.patch<Map<String, dynamic>>(
        any(),
        data: any(named: 'data'),
        options: any(named: 'options'),
        cancelToken: any(named: 'cancelToken'),
      )).thenThrow(exception);
  when(() => dio.delete<void>(any())).thenThrow(exception);
}
