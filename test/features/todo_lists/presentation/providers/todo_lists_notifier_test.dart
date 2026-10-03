import 'dart:async';

import 'package:comfy_list/features/auth/presentation/providers/auth_state.dart';
import 'package:comfy_list/features/todo_lists/data/datasources/firestore_lists_remote.dart';
import 'package:comfy_list/features/todo_lists/data/repositories/todo_lists_repository_impl.dart';
import 'package:comfy_list/features/todo_lists/domain/entities/todo_list.dart';
import 'package:comfy_list/features/todo_lists/domain/repositories/todo_lists_repository.dart';
import 'package:comfy_list/features/todo_lists/presentation/providers/todo_lists_provider.dart';
import 'package:comfy_list/features/todo_lists/presentation/providers/todo_lists_state.dart';
import 'package:comfy_list/features/todos/domain/entities/todo.dart';
import 'package:comfy_list/features/todos/domain/repositories/todos_repository.dart';
import 'package:comfy_list/features/trash/data/datasources/firestore_trash_remote.dart';
import 'package:comfy_list/shared/core/failures/failure.dart';
import 'package:comfy_list/shared/core/result/result.dart';
import 'package:comfy_list/shared/core/time/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/fake_trash_remote.dart';
import '../../../../helpers/provider_scope.dart';
import '../../../../helpers/test_helpers.dart';

class _MockRepo extends Mock implements TodoListsRepository {}

class _MockRemote extends Mock implements FirestoreListsRemote {}

class _MockTodosRepo extends Mock implements TodosRepository {}

void main() {
  late _MockRepo repo;
  late FakeTrashRemote trash;

  setUpAll(() {
    // mocktail necesita un valor de relleno para los matchers de entidades.
    registerFallbackValue(buildTodoList());
    registerFallbackValue(buildTodo());
  });

  test('el repo de la app toma la cadencia del polling del provider', () {
    final container = createTestContainer(
      remoteOverrides: {FirestoreListsRemote: _MockRemote()},
      extra: [
        pollIntervalProvider.overrideWithValue(const Duration(seconds: 3)),
      ],
    );

    final repo =
        container.read(todoListsRepositoryProvider) as TodoListsRepositoryImpl;

    expect(repo.pollInterval, const Duration(seconds: 3));
  });

  setUp(() {
    repo = _MockRepo();
    trash = FakeTrashRemote();
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

  test('delete guarda la lista con sus tareas y undoLastDelete devuelve todo',
      () async {
    final controller = StreamController<List<TodoList>>();
    when(() => repo.watchLists('u1')).thenAnswer((_) => controller.stream);
    when(() => repo.deleteList(uid: 'u1', id: 'L1'))
        .thenAnswer((_) async => const Ok(null));

    final list = buildTodoList(id: 'L1');
    when(() => repo.restoreList(uid: 'u1', list: any(named: 'list')))
        .thenAnswer((_) async => Ok(list));

    final todo = buildTodo(id: 't1');
    final todosRepo = _MockTodosRepo();
    when(() => todosRepo.fetchTodos(uid: 'u1', listId: 'L1'))
        .thenAnswer((_) async => Ok([todo]));
    when(() => todosRepo.restoreTodo(
          uid: 'u1',
          listId: 'L1',
          todo: any(named: 'todo'),
        )).thenAnswer((_) async => Ok(todo));

    final container = createTestContainer(
      remoteOverrides: {FirestoreTrashRemote: trash},
      authedUser: buildAuthUser(),
      repositoryOverrides: {
        TodoListsRepository: repo,
        TodosRepository: todosRepo,
      },
    );
    addTearDown(controller.close);

    expect(container.read(todoListsProvider), isA<TodoListsLoading>());
    controller.add([list]);
    await pumpEventQueue();

    final notifier = container.read(todoListsProvider.notifier);
    expect(await notifier.delete('L1'), isTrue);

    // Las tareas se leen antes de borrar: si no, se perderían en el deshacer.
    verifyInOrder([
      () => todosRepo.fetchTodos(uid: 'u1', listId: 'L1'),
      () => repo.deleteList(uid: 'u1', id: 'L1'),
    ]);

    expect(await notifier.undoLastDelete(), isTrue);

    // La lista vuelve con los datos de antes y sus tareas con ella.
    final restoredList = verify(() => repo.restoreList(
          uid: 'u1',
          list: captureAny(named: 'list'),
        )).captured.single as TodoList;
    expect(restoredList.id, 'L1');
    expect(restoredList.name, 'Compras');

    final restoredTodo = verify(() => todosRepo.restoreTodo(
          uid: 'u1',
          listId: 'L1',
          todo: captureAny(named: 'todo'),
        )).captured.single as Todo;
    expect(restoredTodo.id, 't1');
    expect(restoredTodo.title, 'Comprar pan');

    expect(trash.entries, isEmpty);
  });

  test('sin poder leer las tareas no borra la lista', () async {
    final controller = StreamController<List<TodoList>>();
    when(() => repo.watchLists('u1')).thenAnswer((_) => controller.stream);

    final list = buildTodoList(id: 'L1');
    final todosRepo = _MockTodosRepo();
    when(() => todosRepo.fetchTodos(uid: 'u1', listId: 'L1'))
        .thenAnswer((_) async => const Err<List<Todo>>(NetworkFailure()));

    final container = createTestContainer(
      remoteOverrides: {FirestoreTrashRemote: trash},
      authedUser: buildAuthUser(),
      repositoryOverrides: {
        TodoListsRepository: repo,
        TodosRepository: todosRepo,
      },
    );
    addTearDown(controller.close);

    expect(container.read(todoListsProvider), isA<TodoListsLoading>());
    controller.add([list]);
    await pumpEventQueue();

    final notifier = container.read(todoListsProvider.notifier);

    // Ni borra ni guarda una copia a medias: las tareas se irían en cascada sin
    // poder volver.
    expect(await notifier.delete('L1'), isFalse);
    verifyNever(
      () => repo.deleteList(uid: any(named: 'uid'), id: any(named: 'id')),
    );
    expect(trash.entries, isEmpty);
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
