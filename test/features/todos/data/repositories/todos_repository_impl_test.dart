import 'package:comfy_list/features/todos/data/datasources/firestore_rest_remote.dart';
import 'package:comfy_list/features/todos/data/repositories/todos_repository_impl.dart';
import 'package:comfy_list/features/todos/domain/entities/todo.dart';
import 'package:comfy_list/shared/core/failures/failure.dart';
import 'package:comfy_list/shared/core/result/result.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/test_helpers.dart';

class _MockRemote extends Mock implements FirestoreRestRemote {}

void main() {
  late _MockRemote remote;
  late TodosRepositoryImpl repo;

  setUp(() {
    remote = _MockRemote();
    repo = TodosRepositoryImpl(remote);
  });

  tearDown(() {
    repo.dispose();
  });

  group('TodosRepositoryImpl', () {
    test('fetchTodos returns Ok(list) on remote success', () async {
      when(() => remote.listTodos(uid: 'u1', listId: 'L1'))
          .thenAnswer((_) async => [buildTodo()]);

      final res = await repo.fetchTodos(uid: 'u1', listId: 'L1');

      expect(res.isOk, isTrue);
      final ok = res as Ok<List<Todo>>;
      expect(ok.value, hasLength(1));
      expect(ok.value.first.id, 't1');
    });

    test('fetchTodos returns Err(TimeoutFailure) on receiveTimeout', () async {
      when(() => remote.listTodos(uid: 'u1', listId: 'L1')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.receiveTimeout,
        ),
      );

      final res = await repo.fetchTodos(uid: 'u1', listId: 'L1');

      expect(res.isErr, isTrue);
      expect((res as Err).failure, isA<TimeoutFailure>());
    });

    test('deleteTodo returns Err(NotFoundFailure) on 404', () async {
      when(() => remote.deleteTodo(uid: 'u1', listId: 'L1', id: 't1'))
          .thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.badResponse,
          response: Response<dynamic>(
            requestOptions: RequestOptions(path: ''),
            statusCode: 404,
          ),
        ),
      );

      final res = await repo.deleteTodo(uid: 'u1', listId: 'L1', id: 't1');

      expect(res.isErr, isTrue);
      expect((res as Err).failure, isA<NotFoundFailure>());
    });

    test('updateTodo returns Err(AuthFailure) on 401', () async {
      when(() => remote.updateTodo(
            uid: 'u1',
            listId: 'L1',
            id: 't1',
            title: any(named: 'title'),
            description: any(named: 'description'),
            clearDescription: any(named: 'clearDescription'),
            isDone: any(named: 'isDone'),
          )).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.badResponse,
          response: Response<dynamic>(
            requestOptions: RequestOptions(path: ''),
            statusCode: 401,
          ),
        ),
      );

      final res = await repo.updateTodo(
        uid: 'u1',
        listId: 'L1',
        id: 't1',
        isDone: true,
      );

      expect(res.isErr, isTrue);
      expect((res as Err).failure, isA<AuthFailure>());
    });

    test('fetchTodos returns Err(NetworkFailure) on connectionError', () async {
      when(() => remote.listTodos(uid: 'u1', listId: 'L1')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.connectionError,
        ),
      );

      final res = await repo.fetchTodos(uid: 'u1', listId: 'L1');

      expect(res.isErr, isTrue);
      expect((res as Err).failure, isA<NetworkFailure>());
    });
  });
}
