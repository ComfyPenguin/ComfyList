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
    registerFallbackValue(<Todo>[]);
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
    when(() => repo.deleteList(
          uid: 'u1',
          id: 'L1',
          todoIds: any(named: 'todoIds'),
        )).thenAnswer((_) async => const Ok(null));

    final list = buildTodoList(id: 'L1');
    when(() => repo.restoreList(
          uid: 'u1',
          list: any(named: 'list'),
          todos: any(named: 'todos'),
        )).thenAnswer((_) async => const Ok(null));

    final todo = buildTodo(id: 't1');
    final todosRepo = _MockTodosRepo();
    when(() => todosRepo.refresh(
          uid: any(named: 'uid'),
          listId: any(named: 'listId'),
        )).thenAnswer((_) async {});
    when(() => todosRepo.fetchTodos(uid: 'u1', listId: 'L1'))
        .thenAnswer((_) async => Ok([todo]));

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
      () => repo.deleteList(uid: 'u1', id: 'L1', todoIds: ['t1']),
    ]);

    expect(await notifier.undoLastDelete(), isTrue);

    // La lista vuelve con los datos de antes y sus tareas, en una sola llamada.
    final restored = verify(() => repo.restoreList(
          uid: 'u1',
          list: captureAny(named: 'list'),
          todos: captureAny(named: 'todos'),
        )).captured;
    final restoredList = restored.first as TodoList;
    expect(restoredList.id, 'L1');
    expect(restoredList.name, 'Compras');
    final restoredTodos = restored.last as List<Todo>;
    expect(restoredTodos.map((t) => t.id), ['t1']);
    expect(restoredTodos.single.title, 'Comprar pan');
    verifyNever(() => todosRepo.restoreTodo(
          uid: any(named: 'uid'),
          listId: any(named: 'listId'),
          todo: any(named: 'todo'),
        ));

    expect(trash.entries, isEmpty);
  });

  test('sin poder leer las tareas no borra la lista', () async {
    final controller = StreamController<List<TodoList>>();
    when(() => repo.watchLists('u1')).thenAnswer((_) => controller.stream);

    final list = buildTodoList(id: 'L1');
    final todosRepo = _MockTodosRepo();
    when(() => todosRepo.refresh(
          uid: any(named: 'uid'),
          listId: any(named: 'listId'),
        )).thenAnswer((_) async {});
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
      () => repo.deleteList(
        uid: any(named: 'uid'),
        id: any(named: 'id'),
        todoIds: any(named: 'todoIds'),
      ),
    );
    expect(trash.entries, isEmpty);
  });

  group('borrado optimista', () {
    late StreamController<List<TodoList>> controller;
    late _MockTodosRepo todosRepo;
    late ProviderContainer container;

    setUp(() {
      controller = StreamController<List<TodoList>>();
      todosRepo = _MockTodosRepo();
      when(() => todosRepo.refresh(
            uid: any(named: 'uid'),
            listId: any(named: 'listId'),
          )).thenAnswer((_) async {});
      when(() => repo.watchLists('u1')).thenAnswer((_) => controller.stream);
      when(() => todosRepo.fetchTodos(uid: 'u1', listId: 'L1'))
          .thenAnswer((_) async => Ok([buildTodo(id: 't1')]));
      container = createTestContainer(
        remoteOverrides: {FirestoreTrashRemote: trash},
        authedUser: buildAuthUser(),
        repositoryOverrides: {
          TodoListsRepository: repo,
          TodosRepository: todosRepo,
        },
      );
      addTearDown(controller.close);
    });

    List<String> shownIds() => (container.read(todoListsProvider)
            as TodoListsData)
        .items
        .map((l) => l.id)
        .toList();

    Future<void> seed() async {
      expect(container.read(todoListsProvider), isA<TodoListsLoading>());
      controller.add([buildTodoList(id: 'L1'), buildTodoList(id: 'L2')]);
      await pumpEventQueue();
    }

    test('la lista desaparece antes de que el repositorio responda', () async {
      final deleting = Completer<Result<void>>();
      when(() => repo.deleteList(
            uid: 'u1',
            id: 'L1',
            todoIds: any(named: 'todoIds'),
          )).thenAnswer((_) => deleting.future);
      await seed();

      final result = container.read(todoListsProvider.notifier).delete('L1');

      // Antes de cualquier await: ya no está.
      expect(shownIds(), ['L2']);

      // Un poll a mitad de borrado no la devuelve a la pantalla.
      await pumpEventQueue();
      controller.add([buildTodoList(id: 'L1'), buildTodoList(id: 'L2')]);
      await pumpEventQueue();
      expect(shownIds(), ['L2']);

      deleting.complete(const Ok(null));
      expect(await result, isTrue);

      // El servidor ya no la devuelve y sigue fuera.
      controller.add([buildTodoList(id: 'L2')]);
      await pumpEventQueue();
      expect(shownIds(), ['L2']);
    });

    test('deshacer la enseña aunque el refresco tras borrar fallara', () async {
      when(() => repo.deleteList(
            uid: 'u1',
            id: 'L1',
            todoIds: any(named: 'todoIds'),
          )).thenAnswer((_) async => const Ok(null));
      when(() => repo.restoreList(
            uid: 'u1',
            list: any(named: 'list'),
            todos: any(named: 'todos'),
          )).thenAnswer((_) async => const Ok(null));
      await seed();
      final notifier = container.read(todoListsProvider.notifier);

      expect(await notifier.delete('L1'), isTrue);
      // Sin emisión sin L1: el refresco posterior al borrado no llegó.
      expect(await notifier.undoLastDelete(), isTrue);
      controller.add([buildTodoList(id: 'L1'), buildTodoList(id: 'L2')]);
      await pumpEventQueue();

      expect(shownIds(), containsAll(['L1', 'L2']));
      // Sus tareas se piden ya: un poll durante el borrado las dejó vacías.
      verify(() => todosRepo.refresh(uid: 'u1', listId: 'L1')).called(1);
    });

    test('si el borrado falla la lista vuelve y delete dice que no', () async {
      final deleting = Completer<Result<void>>();
      when(() => repo.deleteList(
            uid: 'u1',
            id: 'L1',
            todoIds: any(named: 'todoIds'),
          )).thenAnswer((_) => deleting.future);
      await seed();

      final result = container.read(todoListsProvider.notifier).delete('L1');
      await pumpEventQueue();
      expect(shownIds(), ['L2']);

      deleting.complete(const Err<void>(ServerFailure('Error 500')));

      expect(await result, isFalse);
      expect(shownIds(), ['L1', 'L2']);
    });

    test('si no se pueden leer las tareas la lista vuelve', () async {
      when(() => todosRepo.fetchTodos(uid: 'u1', listId: 'L1')).thenAnswer(
        (_) async => const Err<List<Todo>>(NetworkFailure()),
      );
      await seed();

      final result = container.read(todoListsProvider.notifier).delete('L1');
      expect(shownIds(), ['L2']);

      expect(await result, isFalse);
      expect(shownIds(), ['L1', 'L2']);
    });
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
