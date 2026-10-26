import 'dart:async';

import 'package:comfy_list/features/auth/presentation/providers/auth_state.dart';
import 'package:comfy_list/features/todos/data/datasources/firestore_rest_remote.dart';
import 'package:comfy_list/features/todos/data/repositories/todos_repository_impl.dart';
import 'package:comfy_list/features/todos/domain/entities/todo.dart';
import 'package:comfy_list/features/todos/domain/repositories/todos_repository.dart';
import 'package:comfy_list/features/todos/presentation/providers/todos_provider.dart';
import 'package:comfy_list/features/todos/presentation/providers/todos_state.dart';
import 'package:comfy_list/features/trash/data/datasources/firestore_trash_remote.dart';
import 'package:comfy_list/features/trash/domain/entities/trash_entry.dart';
import 'package:comfy_list/shared/core/failures/failure.dart';
import 'package:comfy_list/shared/core/result/result.dart';
import 'package:comfy_list/shared/core/time/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/fake_trash_remote.dart';
import '../../../../helpers/provider_scope.dart';
import '../../../../helpers/test_helpers.dart';

class _MockRepo extends Mock implements TodosRepository {}

class _MockRemote extends Mock implements FirestoreRestRemote {}

void main() {
  late _MockRepo repo;
  late FakeTrashRemote trash;

  setUpAll(() {
    // mocktail necesita un valor de relleno para los matchers de entidades.
    registerFallbackValue(buildTodo());
  });

  setUp(() {
    repo = _MockRepo();
    trash = FakeTrashRemote();
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

  test('delete guarda la tarea en la papelera y undoLastDelete la devuelve',
      () async {
    final controller = StreamController<List<Todo>>();
    when(() => repo.watchTodos(uid: 'u1', listId: 'L1'))
        .thenAnswer((_) => controller.stream);
    when(() => repo.deleteTodo(uid: 'u1', listId: 'L1', id: 't1'))
        .thenAnswer((_) async => const Ok(null));
    final todo = buildTodo(id: 't1', title: 'Comprar pan');
    when(() => repo.restoreTodo(
          uid: 'u1',
          listId: 'L1',
          todo: any(named: 'todo'),
        )).thenAnswer((_) async => Ok(todo));

    final container = createTestContainer(
      remoteOverrides: {FirestoreTrashRemote: trash},
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

    // Vuelve tal y como estaba: la papelera guarda la tarea serializada.
    final restored = verify(() => repo.restoreTodo(
          uid: 'u1',
          listId: 'L1',
          todo: captureAny(named: 'todo'),
        )).captured.single as Todo;
    expect(restored.id, 't1');
    expect(restored.title, 'Comprar pan');
    expect(restored.createdAt, todo.createdAt);

    // Y sale de la papelera: ya no hay nada que deshacer.
    expect(trash.entries, isEmpty);
  });

  test('deshace los borrados de uno en uno, el último primero', () async {
    final controller = StreamController<List<Todo>>();
    when(() => repo.watchTodos(uid: 'u1', listId: 'L1'))
        .thenAnswer((_) => controller.stream);
    when(() => repo.deleteTodo(
          uid: 'u1',
          listId: 'L1',
          id: any(named: 'id'),
        )).thenAnswer((_) async => const Ok(null));
    when(() => repo.restoreTodo(
          uid: 'u1',
          listId: 'L1',
          todo: any(named: 'todo'),
        )).thenAnswer((_) async => Ok(buildTodo()));

    final first = buildTodo(id: 't1');
    final second = buildTodo(id: 't2');

    final container = createTestContainer(
      remoteOverrides: {FirestoreTrashRemote: trash},
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

    expect(await notifier.undoLastDelete(), isTrue);
    expect(await notifier.undoLastDelete(), isTrue);
    expect(await notifier.undoLastDelete(), isFalse);

    final restored = verify(() => repo.restoreTodo(
          uid: 'u1',
          listId: 'L1',
          todo: captureAny(named: 'todo'),
        )).captured.cast<Todo>();
    expect(restored.map((todo) => todo.id), ['t2', 't1']);
  });

  test('undoLastDelete con el grupo de la lista delante devuelve solo tareas',
      () async {
    final controller = StreamController<List<Todo>>();
    when(() => repo.watchTodos(uid: 'u1', listId: 'L1'))
        .thenAnswer((_) => controller.stream);
    when(() => repo.restoreTodo(
          uid: 'u1',
          listId: 'L1',
          todo: any(named: 'todo'),
        )).thenAnswer((_) async => Ok(buildTodo()));

    // Lo último que entró en la papelera es el borrado de la lista L1: el grupo
    // lleva la lista delante y sus tareas detrás, y la lista no se puede leer
    // como una tarea.
    final list = buildTodoList(id: 'L1');
    final now = DateTime.now().toUtc();
    await trash.createEntries(
      uid: 'u1',
      groupId: 'g1',
      items: [TrashItem(
        kind: TrashKind.todo,
        itemId: 't1',
        parentId: 'L1',
        label: 'Pan',
        payload: buildTodo(id: 't1', title: 'Pan').toJson(),
      )],
      deletedAt: now.subtract(const Duration(minutes: 1)),
    );
    await trash.createEntries(
      uid: 'u1',
      groupId: 'g2',
      items: [TrashItem(
        kind: TrashKind.list,
        itemId: list.id,
        label: list.name,
        payload: list.toJson(),
      )],
      deletedAt: now,
    );
    await trash.createEntries(
      uid: 'u1',
      groupId: 'g2',
      items: [TrashItem(
        kind: TrashKind.todo,
        itemId: 't2',
        parentId: list.id,
        label: 'Leche',
        payload: buildTodo(id: 't2', title: 'Leche').toJson(),
      )],
      deletedAt: now,
    );

    final container = createTestContainer(
      remoteOverrides: {FirestoreTrashRemote: trash},
      authedUser: buildAuthUser(),
      repositoryOverrides: {TodosRepository: repo},
    );
    addTearDown(controller.close);

    final notifier = container.read(todosProvider('L1').notifier);

    expect(await notifier.undoLastDelete(), isTrue);

    // Vuelve la tarea del grupo, y solo ella: la lista sigue en la papelera,
    // que todavía no está de vuelta en la app.
    final restored = verify(() => repo.restoreTodo(
          uid: 'u1',
          listId: 'L1',
          todo: captureAny(named: 'todo'),
        )).captured.single as Todo;
    expect(restored.id, 't2');
    expect(trash.entries.map((e) => e.itemId), ['t1', 'L1']);
  });

  test('undoLastDelete dice que no si la restauración falla', () async {
    final controller = StreamController<List<Todo>>();
    when(() => repo.watchTodos(uid: 'u1', listId: 'L1'))
        .thenAnswer((_) => controller.stream);
    when(() => repo.deleteTodo(uid: 'u1', listId: 'L1', id: 't1'))
        .thenAnswer((_) async => const Ok(null));
    final todo = buildTodo(id: 't1');
    when(() => repo.restoreTodo(
          uid: 'u1',
          listId: 'L1',
          todo: any(named: 'todo'),
        )).thenAnswer((_) async => const Err<Todo>(ServerFailure('Error 500')));

    final container = createTestContainer(
      remoteOverrides: {FirestoreTrashRemote: trash},
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

    // El borrado sigue en la papelera: se puede reintentar.
    expect(trash.entries, hasLength(1));
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
