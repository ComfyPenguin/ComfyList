import 'dart:async';

import 'package:comfy_list/features/auth/presentation/providers/auth_state.dart';
import 'package:comfy_list/features/todo_lists/domain/entities/todo_list.dart';
import 'package:comfy_list/features/todo_lists/domain/repositories/todo_lists_repository.dart';
import 'package:comfy_list/features/todo_lists/presentation/providers/todo_lists_provider.dart';
import 'package:comfy_list/features/todo_lists/presentation/providers/todo_lists_state.dart';
import 'package:comfy_list/shared/core/failures/failure.dart';
import 'package:comfy_list/shared/core/result/result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/provider_scope.dart';
import '../../../../helpers/test_helpers.dart';

class _MockRepo extends Mock implements TodoListsRepository {}

void main() {
  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
  });

  ProviderContainer buildContainer() => createTestContainer(
        authedUser: buildAuthUser(),
        repositoryOverrides: {TodoListsRepository: repo},
      );

  test('bootstrap transitions Initial → Loading → Data on first emission',
      () async {
    final controller = StreamController<List<TodoList>>();
    when(() => repo.watchLists('u1')).thenAnswer((_) => controller.stream);

    final container = buildContainer();
    addTearDown(controller.close);

    expect(container.read(todoListsProvider), isA<TodoListsLoading>());

    controller.add([buildTodoList()]);
    await pumpEventQueue();

    final state = container.read(todoListsProvider);
    expect(state, isA<TodoListsData>());
    expect((state as TodoListsData).items, hasLength(1));
  });

  test('watcher error before any Data transitions to Error', () async {
    final controller = StreamController<List<TodoList>>();
    when(() => repo.watchLists('u1')).thenAnswer((_) => controller.stream);

    final container = buildContainer();
    addTearDown(controller.close);

    // Inicia la suscripción
    expect(container.read(todoListsProvider), isA<TodoListsLoading>());

    controller.addError(const UnknownFailure());
    await pumpEventQueue();

    expect(container.read(todoListsProvider), isA<TodoListsError>());
  });

  test('create propagates Err(Failure) into the state', () async {
    final controller = StreamController<List<TodoList>>();
    when(() => repo.watchLists('u1')).thenAnswer((_) => controller.stream);
    when(() => repo.createList(
          uid: 'u1',
          name: 'Compras',
          iconKey: 'cart',
        )).thenAnswer(
      (_) async => const Err<TodoList>(
        ServerFailure('Error 500'),
      ),
    );

    final container = buildContainer();
    addTearDown(controller.close);

    // Inicia la suscripción
    expect(container.read(todoListsProvider), isA<TodoListsLoading>());

    // Emite data inicial para que el notifier entre en estado Data
    controller.add(<TodoList>[]);
    await pumpEventQueue();

    await container.read(todoListsProvider.notifier).create(
          name: 'Compras',
          iconKey: 'cart',
        );

    final state = container.read(todoListsProvider);
    expect(state, isA<TodoListsError>());
    expect((state as TodoListsError).failure, isA<ServerFailure>());
  });

  test('create with Ok does not change state from Data', () async {
    final controller = StreamController<List<TodoList>>();
    when(() => repo.watchLists('u1')).thenAnswer((_) => controller.stream);
    when(() => repo.createList(
          uid: 'u1',
          name: 'X',
          iconKey: 'cart',
        )).thenAnswer(
      (_) async => Ok(buildTodoList()),
    );

    final container = buildContainer();
    addTearDown(controller.close);

    // Inicia la suscripción
    expect(container.read(todoListsProvider), isA<TodoListsLoading>());

    controller.add([buildTodoList(id: 'L1')]);
    await pumpEventQueue();

    final before = container.read(todoListsProvider);
    expect(before, isA<TodoListsData>());

    await container.read(todoListsProvider.notifier).create(
          name: 'X',
          iconKey: 'cart',
        );

    final after = container.read(todoListsProvider);
    expect(after, isA<TodoListsData>());
    // Sin flicker: la lista existente no se ha reemplazado
    expect((after as TodoListsData).items, hasLength(1));
  });

  test('bootstrap returns Initial when auth is Unauthenticated', () async {
    final container = createTestContainer(
      authState: const Unauthenticated(),
      repositoryOverrides: {TodoListsRepository: repo},
    );

    expect(container.read(todoListsProvider), isA<TodoListsInitial>());
    verifyNever(() => repo.watchLists(any()));
  });
}
