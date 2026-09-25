import 'dart:async';

import 'package:comfy_list/features/auth/presentation/providers/auth_state.dart';
import 'package:comfy_list/features/todos/data/datasources/firestore_rest_remote.dart';
import 'package:comfy_list/features/todos/data/repositories/todos_repository_impl.dart';
import 'package:comfy_list/features/todos/domain/entities/todo.dart';
import 'package:comfy_list/features/todos/domain/repositories/todos_repository.dart';
import 'package:comfy_list/features/todos/presentation/providers/todos_provider.dart';
import 'package:comfy_list/features/todos/presentation/providers/todos_state.dart';
import 'package:comfy_list/shared/core/failures/failure.dart';
import 'package:comfy_list/shared/core/result/result.dart';
import 'package:comfy_list/shared/core/time/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/provider_scope.dart';
import '../../../../helpers/test_helpers.dart';

class _MockRepo extends Mock implements TodosRepository {}

class _MockRemote extends Mock implements FirestoreRestRemote {}

void main() {
  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
  });

  test('el repo de la app toma la cadencia del polling del provider', () {
    final container = createTestContainer(
      remoteOverrides: {FirestoreRestRemote: _MockRemote()},
      extra: [
        pollIntervalProvider.overrideWithValue(const Duration(seconds: 3)),
      ],
    );

    final repo = container.read(todosRepositoryProvider) as TodosRepositoryImpl;

    expect(repo.pollInterval, const Duration(seconds: 3));
  });

  test('build returns TodosInitial when auth is not Authenticated', () async {
    final container = createTestContainer(
      authState: const Unauthenticated(),
      repositoryOverrides: {TodosRepository: repo},
    );

    expect(container.read(todosProvider('L1')), isA<TodosInitial>());
    verifyNever(() => repo.watchTodos(uid: any(named: 'uid'), listId: any(named: 'listId')));
  });

  test('build subscribes to watchTodos when auth is Authenticated', () async {
    final controller = StreamController<List<Todo>>();
    when(() => repo.watchTodos(uid: 'u1', listId: 'L1'))
        .thenAnswer((_) => controller.stream);

    final container = createTestContainer(
      authedUser: buildAuthUser(),
      repositoryOverrides: {TodosRepository: repo},
    );
    addTearDown(controller.close);

    expect(container.read(todosProvider('L1')), isA<TodosLoading>());

    controller.add(<Todo>[]);
    await pumpEventQueue();

    final state = container.read(todosProvider('L1'));
    expect(state, isA<TodosData>());
    expect((state as TodosData).items, isEmpty);
  });

  test('toggleDone calls updateTodo with isDone', () async {
    final controller = StreamController<List<Todo>>();
    when(() => repo.watchTodos(uid: 'u1', listId: 'L1'))
        .thenAnswer((_) => controller.stream);
    when(() => repo.updateTodo(
          uid: 'u1',
          listId: 'L1',
          id: 't1',
          title: any(named: 'title'),
          description: any(named: 'description'),
          clearDescription: any(named: 'clearDescription'),
          isDone: true,
        )).thenAnswer((_) async => Ok(buildTodo(id: 't1', isDone: true)));

    final container = createTestContainer(
      authedUser: buildAuthUser(),
      repositoryOverrides: {TodosRepository: repo},
    );
    addTearDown(controller.close);

    expect(container.read(todosProvider('L1')), isA<TodosLoading>());

    await container.read(todosProvider('L1').notifier).toggleDone('t1', true);

    verify(() => repo.updateTodo(
          uid: 'u1',
          listId: 'L1',
          id: 't1',
          title: any(named: 'title'),
          description: any(named: 'description'),
          clearDescription: any(named: 'clearDescription'),
          isDone: true,
        )).called(1);
  });

  test('delete recuerda la tarea y undoLastDelete la devuelve', () async {
    final controller = StreamController<List<Todo>>();
    when(() => repo.watchTodos(uid: 'u1', listId: 'L1'))
        .thenAnswer((_) => controller.stream);
    when(() => repo.deleteTodo(uid: 'u1', listId: 'L1', id: 't1'))
        .thenAnswer((_) async => const Ok(null));
    final todo = buildTodo(id: 't1', title: 'Comprar pan');
    when(() => repo.restoreTodo(uid: 'u1', listId: 'L1', todo: todo))
        .thenAnswer((_) async => Ok(todo));

    final container = createTestContainer(
      authedUser: buildAuthUser(),
      repositoryOverrides: {TodosRepository: repo},
    );
    addTearDown(controller.close);

    expect(container.read(todosProvider('L1')), isA<TodosLoading>());
    controller.add([todo]);
    await pumpEventQueue();

    final notifier = container.read(todosProvider('L1').notifier);
    await notifier.delete('t1');

    expect(await notifier.undoLastDelete(), isTrue);
    verify(() => repo.restoreTodo(uid: 'u1', listId: 'L1', todo: todo))
        .called(1);
  });

  test('solo se deshace el último borrado', () async {
    final controller = StreamController<List<Todo>>();
    when(() => repo.watchTodos(uid: 'u1', listId: 'L1'))
        .thenAnswer((_) => controller.stream);
    when(() => repo.deleteTodo(
          uid: 'u1',
          listId: 'L1',
          id: any(named: 'id'),
        )).thenAnswer((_) async => const Ok(null));

    final first = buildTodo(id: 't1');
    final second = buildTodo(id: 't2');
    when(() => repo.restoreTodo(uid: 'u1', listId: 'L1', todo: second))
        .thenAnswer((_) async => Ok(second));

    final container = createTestContainer(
      authedUser: buildAuthUser(),
      repositoryOverrides: {TodosRepository: repo},
    );
    addTearDown(controller.close);

    expect(container.read(todosProvider('L1')), isA<TodosLoading>());
    controller.add([first, second]);
    await pumpEventQueue();

    final notifier = container.read(todosProvider('L1').notifier);
    await notifier.delete('t1');
    await notifier.delete('t2');
    await notifier.undoLastDelete();

    verify(() => repo.restoreTodo(uid: 'u1', listId: 'L1', todo: second))
        .called(1);
    verifyNever(() => repo.restoreTodo(uid: 'u1', listId: 'L1', todo: first));
  });

  test('undoLastDelete dice que no si la restauración falla', () async {
    final controller = StreamController<List<Todo>>();
    when(() => repo.watchTodos(uid: 'u1', listId: 'L1'))
        .thenAnswer((_) => controller.stream);
    when(() => repo.deleteTodo(uid: 'u1', listId: 'L1', id: 't1'))
        .thenAnswer((_) async => const Ok(null));
    final todo = buildTodo(id: 't1');
    when(() => repo.restoreTodo(uid: 'u1', listId: 'L1', todo: todo))
        .thenAnswer((_) async => const Err<Todo>(ServerFailure('Error 500')));

    final container = createTestContainer(
      authedUser: buildAuthUser(),
      repositoryOverrides: {TodosRepository: repo},
    );
    addTearDown(controller.close);

    expect(container.read(todosProvider('L1')), isA<TodosLoading>());
    controller.add([todo]);
    await pumpEventQueue();

    final notifier = container.read(todosProvider('L1').notifier);
    await notifier.delete('t1');

    expect(await notifier.undoLastDelete(), isFalse);
  });

  test('create Err propagates to state', () async {
    final controller = StreamController<List<Todo>>();
    when(() => repo.watchTodos(uid: 'u1', listId: 'L1'))
        .thenAnswer((_) => controller.stream);
    when(() => repo.createTodo(
          uid: 'u1',
          listId: 'L1',
          title: any(named: 'title'),
          description: any(named: 'description'),
        )).thenAnswer(
      (_) async => const Err<Todo>(
        ServerFailure('Error 500'),
      ),
    );

    final container = createTestContainer(
      authedUser: buildAuthUser(),
      repositoryOverrides: {TodosRepository: repo},
    );
    addTearDown(controller.close);

    expect(container.read(todosProvider('L1')), isA<TodosLoading>());

    await container.read(todosProvider('L1').notifier).create(title: 'X');

    final state = container.read(todosProvider('L1'));
    expect(state, isA<TodosError>());
    expect((state as TodosError).failure, isA<ServerFailure>());
  });
}
