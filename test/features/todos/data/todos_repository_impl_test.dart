import 'package:comfy_list/features/todos/data/datasources/firestore_rest_remote.dart';
import 'package:comfy_list/features/todos/data/repositories/todos_repository_impl.dart';
import 'package:comfy_list/features/todos/domain/entities/todo.dart';
import 'package:comfy_list/shared/core/failures/failure.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemote extends Mock implements FirestoreRestRemote {}

Todo _buildTodo(String id, {bool done = false}) => Todo(
      id: id,
      title: 'T$id',
      isDone: done,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
    );

const _uid = 'u1';
const _listId = 'l1';

void main() {
  late _MockRemote remote;
  late TodosRepositoryImpl repo;

  setUp(() {
    remote = _MockRemote();
    repo = TodosRepositoryImpl(remote);
  });

  tearDown(() => repo.dispose());

  test('fetchTodos delega en remote y devuelve Ok', () async {
    when(() => remote.listTodos(uid: _uid, listId: _listId))
        .thenAnswer((_) async => [_buildTodo('a'), _buildTodo('b')]);

    final result = await repo.fetchTodos(uid: _uid, listId: _listId);
    result.fold(
      onOk: (list) => expect(list.length, 2),
      onErr: (_) => fail('Esperaba Ok'),
    );
  });

  test('createTodo retorna Ok y dispara refresh del watcher', () async {
    final created = _buildTodo('new');
    when(() => remote.createTodo(
          uid: any(named: 'uid'),
          listId: any(named: 'listId'),
          title: any(named: 'title'),
          description: any(named: 'description'),
        )).thenAnswer((_) async => created);
    when(() => remote.listTodos(uid: _uid, listId: _listId))
        .thenAnswer((_) async => <Todo>[created]);

    final result =
        await repo.createTodo(uid: _uid, listId: _listId, title: 'Algo');
    result.fold(
      onOk: (t) => expect(t.id, 'new'),
      onErr: (_) => fail('Esperaba Ok'),
    );
  });

  test('mapea connectionError a NetworkFailure', () async {
    when(() => remote.listTodos(uid: _uid, listId: _listId)).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/'),
        type: DioExceptionType.connectionError,
      ),
    );

    final result = await repo.fetchTodos(uid: _uid, listId: _listId);
    result.fold(
      onOk: (_) => fail('Esperaba Err'),
      onErr: (f) => expect(f, isA<NetworkFailure>()),
    );
  });

  test('mapea 401 a AuthFailure', () async {
    when(() => remote.listTodos(uid: _uid, listId: _listId)).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/'),
          statusCode: 401,
        ),
      ),
    );

    final result = await repo.fetchTodos(uid: _uid, listId: _listId);
    result.fold(
      onOk: (_) => fail('Esperaba Err'),
      onErr: (f) => expect(f, isA<AuthFailure>()),
    );
  });

  test('watchTodos emite la lista inicial al suscribirse', () async {
    when(() => remote.listTodos(uid: _uid, listId: _listId))
        .thenAnswer((_) async => [_buildTodo('a')]);

    final stream = repo.watchTodos(uid: _uid, listId: _listId);
    final first = await stream.first;
    expect(first.length, 1);
    expect(first.first.id, 'a');
  });
}
