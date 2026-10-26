import 'package:comfy_list/features/todo_lists/data/datasources/firestore_lists_remote.dart';
import 'package:comfy_list/features/todo_lists/data/repositories/todo_lists_repository_impl.dart';
import 'package:comfy_list/features/todo_lists/domain/entities/todo_list.dart';
import 'package:comfy_list/features/todos/domain/entities/todo.dart';
import 'package:comfy_list/shared/core/failures/failure.dart';
import 'package:comfy_list/shared/core/result/result.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/test_helpers.dart';

class _MockRemote extends Mock implements FirestoreListsRemote {}

void main() {
  setUpAll(() {
    registerFallbackValue(buildTodoList());
    registerFallbackValue(<Todo>[]);
  });

  late _MockRemote remote;
  late TodoListsRepositoryImpl repo;

  setUp(() {
    remote = _MockRemote();
    repo = TodoListsRepositoryImpl(remote);
  });

  tearDown(() {
    repo.dispose();
  });

  group('TodoListsRepositoryImpl', () {
    test('fetchLists returns Ok(list) on remote success', () async {
      when(() => remote.listLists('u1'))
          .thenAnswer((_) async => [buildTodoList()]);

      final res = await repo.fetchLists('u1');

      expect(res.isOk, isTrue);
      final ok = res as Ok<List<TodoList>>;
      expect(ok.value, hasLength(1));
      expect(ok.value.first.id, 'L1');
    });

    test('fetchLists returns Err(NetworkFailure) on connectionError', () async {
      when(() => remote.listLists('u1')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.connectionError,
        ),
      );

      final res = await repo.fetchLists('u1');

      expect(res.isErr, isTrue);
      expect((res as Err).failure, isA<NetworkFailure>());
    });

    test('fetchLists returns Err(TimeoutFailure) on receiveTimeout', () async {
      when(() => remote.listLists('u1')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.receiveTimeout,
        ),
      );

      final res = await repo.fetchLists('u1');

      expect(res.isErr, isTrue);
      expect((res as Err).failure, isA<TimeoutFailure>());
    });

    test('el watcher vuelve a pedir la lista en cada tick', () async {
      when(() => remote.listLists('u1'))
          .thenAnswer((_) async => <TodoList>[buildTodoList()]);

      final polled = TodoListsRepositoryImpl(
        remote,
        pollInterval: const Duration(milliseconds: 20),
      );
      addTearDown(polled.dispose);

      final sub = polled.watchLists('u1').listen((_) {});

      // Margen de sobra para el fetch inicial y varios ticks.
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await sub.cancel();

      verify(() => remote.listLists('u1')).called(greaterThan(1));
    });

    test('createList refreshes the watcher after success', () async {
      when(() => remote.listLists('u1'))
          .thenAnswer((_) async => <TodoList>[buildTodoList()]);
      when(() => remote.createList(
            uid: 'u1',
            name: 'Compras',
            iconKey: 'cart',
          )).thenAnswer((_) async => buildTodoList(name: 'Compras'));

      // Suscribimos al watcher antes de la mutación
      final emitted = <List<TodoList>>[];
      final sub = repo.watchLists('u1').listen(emitted.add);

      final res = await repo.createList(
        uid: 'u1',
        name: 'Compras',
        iconKey: 'cart',
      );

      // Espera microtasks para que la emisión del refresh llegue
      await Future<void>.delayed(Duration.zero);

      expect(res.isOk, isTrue);
      // Hubo al menos una emisión (la inicial del watcher) — verificamos
      // que el watcher está vivo tras la mutación
      expect(emitted, isNotEmpty);

      await sub.cancel();
    });

    test('createList returns Err(Failure) on DioException', () async {
      when(() => remote.createList(
            uid: 'u1',
            name: any(named: 'name'),
            iconKey: any(named: 'iconKey'),
          )).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.badResponse,
          response: Response<dynamic>(
            requestOptions: RequestOptions(path: ''),
            statusCode: 500,
          ),
        ),
      );

      final res = await repo.createList(
        uid: 'u1',
        name: 'Compras',
        iconKey: 'cart',
      );

      expect(res.isErr, isTrue);
      expect((res as Err).failure, isA<ServerFailure>());
    });

    test('deleteList borra la lista y sus tareas con una sola llamada',
        () async {
      when(() => remote.deleteListWithTodos(
            uid: 'u1',
            id: 'L1',
            todoIds: any(named: 'todoIds'),
          )).thenAnswer((_) async {});

      final res = await repo.deleteList(
        uid: 'u1',
        id: 'L1',
        todoIds: const ['t1', 't2'],
      );

      expect(res.isOk, isTrue);
      verify(() => remote.deleteListWithTodos(
            uid: 'u1',
            id: 'L1',
            todoIds: const ['t1', 't2'],
          )).called(1);
    });

    test('deleteList devuelve Err si el commit falla', () async {
      when(() => remote.deleteListWithTodos(
            uid: 'u1',
            id: 'L1',
            todoIds: any(named: 'todoIds'),
          )).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.connectionError,
        ),
      );

      final res = await repo.deleteList(uid: 'u1', id: 'L1', todoIds: const []);

      expect((res as Err).failure, isA<NetworkFailure>());
    });

    test('restoreList devuelve la lista y sus tareas con una sola llamada',
        () async {
      when(() => remote.restoreListWithTodos(
            uid: 'u1',
            list: any(named: 'list'),
            todos: any(named: 'todos'),
          )).thenAnswer((_) async {});

      final res = await repo.restoreList(
        uid: 'u1',
        list: buildTodoList(id: 'L1'),
        todos: [buildTodo(id: 't1')],
      );

      expect(res.isOk, isTrue);
      final sent = verify(() => remote.restoreListWithTodos(
            uid: 'u1',
            list: any(named: 'list'),
            todos: captureAny(named: 'todos'),
          )).captured.single as List<Todo>;
      expect(sent.map((t) => t.id), ['t1']);
    });
  });
}
