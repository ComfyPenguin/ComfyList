import 'dart:async';

import 'package:comfy_list/features/auth/presentation/providers/auth_state.dart';
import 'package:comfy_list/features/todos/domain/entities/todo.dart';
import 'package:comfy_list/features/todos/domain/repositories/todos_repository.dart';
import 'package:comfy_list/features/todos/presentation/providers/todos_provider.dart';
import 'package:comfy_list/features/todos/presentation/providers/todos_state.dart';
import 'package:comfy_list/shared/core/failures/failure.dart';
import 'package:comfy_list/shared/core/result/result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/provider_scope.dart';
import '../../../../helpers/test_helpers.dart';

class _MockRepo extends Mock implements TodosRepository {}

void main() {
  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
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
