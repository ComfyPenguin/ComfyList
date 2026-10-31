import 'dart:async';

import 'package:comfy_list/features/auth/presentation/providers/auth_state.dart';
import 'package:comfy_list/features/todo_lists/data/datasources/firestore_lists_remote.dart';
import 'package:comfy_list/features/todo_lists/domain/entities/todo_list.dart';
import 'package:comfy_list/features/todo_lists/domain/repositories/todo_lists_repository.dart';
import 'package:comfy_list/features/todo_lists/presentation/providers/todo_lists_provider.dart';
import 'package:comfy_list/features/todo_lists/presentation/providers/todo_lists_state.dart';
import 'package:comfy_list/features/todos/domain/entities/todo.dart';
import 'package:comfy_list/features/todos/domain/repositories/todos_repository.dart';
import 'package:comfy_list/features/trash/data/datasources/firestore_trash_remote.dart';
import 'package:comfy_list/features/trash/domain/entities/trash_entry.dart';
import 'package:comfy_list/features/trash/domain/repositories/trash_repository.dart';
import 'package:comfy_list/features/trash/presentation/providers/trash_provider.dart';
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

class _MockTrash extends Mock implements TrashRepository {}

void main() {
  late _MockRepo repo;
  late FakeTrashRemote trash;

  setUpAll(() {
    // mocktail necesita un valor de relleno para los matchers de entidades.
    registerFallbackValue(buildTodoList());
    registerFallbackValue(buildTodo());
    registerFallbackValue(<Todo>[]);
  });

  test('el repo de la app toma la cadencia del polling del provider', () async {
    final remote = _MockRemote();
    when(() => remote.listLists('u1')).thenAnswer((_) async => <TodoList>[]);
    final container = createTestContainer(
      remoteOverrides: {FirestoreListsRemote: remote},
      extra: [
        pollIntervalProvider.overrideWithValue(const Duration(milliseconds: 20)),
      ],
    );
    final sub = container
        .read(todoListsRepositoryProvider)
        .watchLists('u1')
        .listen((_) {});
    addTearDown(sub.cancel);

    await Future<void>.delayed(const Duration(milliseconds: 150));

    verify(() => remote.listLists('u1')).called(greaterThan(1));
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

  group('mutaciones', () {
    late StreamController<List<TodoList>> controller;
    late ProviderContainer container;

    setUp(() async {
      controller = StreamController<List<TodoList>>();
      when(() => repo.watchLists('u1')).thenAnswer((_) => controller.stream);
      container = buildContainer();
      addTearDown(controller.close);
      expect(container.read(todoListsProvider), isA<TodoListsLoading>());
      controller.add([buildTodoList(id: 'L1')]);
      await pumpEventQueue();
    });

    test('create devuelve true si sale bien', () async {
      when(() => repo.createList(
            uid: 'u1',
            name: 'Compras',
            iconKey: 'cart',
          )).thenAnswer((_) async => Ok(buildTodoList(id: 'L2')));

      final ok = await container
          .read(todoListsProvider.notifier)
          .create(name: 'Compras', iconKey: 'cart');

      expect(ok, isTrue);
    });

    test('create devuelve false si falla y no vacía las listas', () async {
      when(() => repo.createList(
            uid: 'u1',
            name: 'Compras',
            iconKey: 'cart',
          )).thenAnswer(
        (_) async => const Err<TodoList>(ServerFailure('Error 500')),
      );

      final ok = await container
          .read(todoListsProvider.notifier)
          .create(name: 'Compras', iconKey: 'cart');

      expect(ok, isFalse);
      final state = container.read(todoListsProvider);
      expect(state, isA<TodoListsData>());
      expect((state as TodoListsData).items.map((l) => l.id), ['L1']);
    });

    test('updateFields devuelve false si falla', () async {
      when(() => repo.updateList(
            uid: 'u1',
            id: 'L1',
            name: any(named: 'name'),
            iconKey: any(named: 'iconKey'),
          )).thenAnswer((_) async => const Err<TodoList>(NetworkFailure()));

      final ok = await container
          .read(todoListsProvider.notifier)
          .updateFields(id: 'L1', name: 'Nuevo');

      expect(ok, isFalse);
    });
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

  test('delete guarda la lista con sus tareas y undo devuelve todo',
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
    final deleted = await notifier.delete('L1');
    expect(deleted, isNotNull);

    // Las tareas se leen antes de borrar: si no, se perderían en el deshacer.
    verifyInOrder([
      () => todosRepo.fetchTodos(uid: 'u1', listId: 'L1'),
      () => repo.deleteList(uid: 'u1', id: 'L1', todoIds: ['t1']),
    ]);

    expect(await notifier.undo(deleted!), isTrue);

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
    expect(await notifier.delete('L1'), isNull);
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
      expect(await result, isNotNull);

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

      final deleted = await notifier.delete('L1');
      expect(deleted, isNotNull);
      // Sin emisión sin L1: el refresco posterior al borrado no llegó.
      expect(await notifier.undo(deleted!), isTrue);
      controller.add([buildTodoList(id: 'L1'), buildTodoList(id: 'L2')]);
      await pumpEventQueue();

      expect(shownIds(), containsAll(['L1', 'L2']));
      // Sus tareas se piden ya: un poll durante el borrado las dejó vacías.
      verify(() => todosRepo.refresh(uid: 'u1', listId: 'L1')).called(1);
    });

    test('si el borrado falla la lista vuelve y delete devuelve null', () async {
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

      expect(await result, isNull);
      expect(shownIds(), ['L1', 'L2']);
      // Y no se queda una copia de algo que no se borró.
      expect(trash.entries, isEmpty);
    });

    test('si no se pueden leer las tareas la lista vuelve', () async {
      when(() => todosRepo.fetchTodos(uid: 'u1', listId: 'L1')).thenAnswer(
        (_) async => const Err<List<Todo>>(NetworkFailure()),
      );
      await seed();

      final result = container.read(todoListsProvider.notifier).delete('L1');
      expect(shownIds(), ['L2']);

      expect(await result, isNull);
      expect(shownIds(), ['L1', 'L2']);
    });

    test('si no se puede guardar la copia la lista vuelve y no se borra',
        () async {
      registerFallbackValue(<TrashItem>[]);
      final trashRepo = _MockTrash();
      when(() => trashRepo.save(
            uid: any(named: 'uid'),
            items: any(named: 'items'),
          )).thenAnswer((_) async => const Err(NetworkFailure()));
      final container = createTestContainer(
        authedUser: buildAuthUser(),
        repositoryOverrides: {
          TodoListsRepository: repo,
          TodosRepository: todosRepo,
        },
        extra: [trashRepositoryProvider.overrideWithValue(trashRepo)],
      );
      expect(container.read(todoListsProvider), isA<TodoListsLoading>());
      controller.add([buildTodoList(id: 'L1'), buildTodoList(id: 'L2')]);
      await pumpEventQueue();

      final deleted =
          await container.read(todoListsProvider.notifier).delete('L1');

      expect(deleted, isNull);
      final shown = (container.read(todoListsProvider) as TodoListsData)
          .items
          .map((l) => l.id);
      expect(shown, ['L1', 'L2']);
      verifyNever(() => repo.deleteList(
            uid: any(named: 'uid'),
            id: any(named: 'id'),
            todoIds: any(named: 'todoIds'),
          ));
    });

    test('delete de una lista que no está cargada no borra nada', () async {
      await seed();

      final deleted =
          await container.read(todoListsProvider.notifier).delete('otra');

      expect(deleted, isNull);
      verifyNever(() => repo.deleteList(
            uid: any(named: 'uid'),
            id: any(named: 'id'),
            todoIds: any(named: 'todoIds'),
          ));
    });

    test('undo devuelve la lista que se le da y deja la otra en la papelera',
        () async {
      when(() => todosRepo.fetchTodos(uid: 'u1', listId: 'L2'))
          .thenAnswer((_) async => const Ok(<Todo>[]));
      when(() => repo.deleteList(
            uid: 'u1',
            id: any(named: 'id'),
            todoIds: any(named: 'todoIds'),
          )).thenAnswer((_) async => const Ok(null));
      when(() => repo.restoreList(
            uid: 'u1',
            list: any(named: 'list'),
            todos: any(named: 'todos'),
          )).thenAnswer((_) async => const Ok(null));
      await seed();
      final notifier = container.read(todoListsProvider.notifier);
      final first = await notifier.delete('L1');
      await notifier.delete('L2');

      expect(await notifier.undo(first!), isTrue);

      final restored = verify(() => repo.restoreList(
            uid: 'u1',
            list: captureAny(named: 'list'),
            todos: any(named: 'todos'),
          )).captured.single as TodoList;
      expect(restored.id, 'L1');
      // La lista L2 y sus tareas (ninguna) siguen en la papelera.
      expect(trash.entries.map((e) => e.itemId), ['L2']);
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
