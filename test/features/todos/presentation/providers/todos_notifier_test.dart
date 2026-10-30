import 'dart:async';

import 'package:comfy_list/features/auth/presentation/providers/auth_state.dart';
import 'package:comfy_list/features/todos/data/datasources/firestore_rest_remote.dart';
import 'package:comfy_list/features/todos/domain/entities/todo.dart';
import 'package:comfy_list/features/todos/domain/repositories/todos_repository.dart';
import 'package:comfy_list/features/todos/presentation/providers/todos_provider.dart';
import 'package:comfy_list/features/todos/presentation/providers/todos_state.dart';
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

class _MockRepo extends Mock implements TodosRepository {}

class _MockRemote extends Mock implements FirestoreRestRemote {}

class _MockTrash extends Mock implements TrashRepository {}

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

  test('el repo de la app toma la cadencia del polling del provider', () async {
    final remote = _MockRemote();
    when(() => remote.listTodos(uid: 'u1', listId: 'L1'))
        .thenAnswer((_) async => <Todo>[]);
    final container = createTestContainer(
      remoteOverrides: {FirestoreRestRemote: remote},
      extra: [
        pollIntervalProvider.overrideWithValue(
          const Duration(milliseconds: 20),
        ),
      ],
    );
    final sub = container
        .read(todosRepositoryProvider)
        .watchTodos(uid: 'u1', listId: 'L1')
        .listen((_) {});
    addTearDown(sub.cancel);

    await Future<void>.delayed(const Duration(milliseconds: 150));

    verify(() => remote.listTodos(uid: 'u1', listId: 'L1'))
        .called(greaterThan(1));
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

  /// Un contenedor con la lista L1 ya cargada y la papelera en memoria.
  Future<ProviderContainer> loaded(List<Todo> todos) async {
    final controller = StreamController<List<Todo>>();
    when(() => repo.watchTodos(uid: 'u1', listId: 'L1'))
        .thenAnswer((_) => controller.stream);
    final container = createTestContainer(
      remoteOverrides: {FirestoreTrashRemote: trash},
      authedUser: buildAuthUser(),
      repositoryOverrides: {TodosRepository: repo},
    );
    addTearDown(controller.close);

    expect(container.read(todosProvider('L1')), isA<TodosLoading>());
    controller.add(todos);
    await pumpEventQueue();
    return container;
  }

  test('delete guarda la tarea en la papelera y undo la devuelve', () async {
    when(() => repo.deleteTodo(uid: 'u1', listId: 'L1', id: 't1'))
        .thenAnswer((_) async => const Ok(null));
    final todo = buildTodo(id: 't1', title: 'Comprar pan');
    when(() => repo.restoreTodo(
          uid: 'u1',
          listId: 'L1',
          todo: any(named: 'todo'),
        )).thenAnswer((_) async => Ok(todo));
    final container = await loaded([todo]);
    final notifier = container.read(todosProvider('L1').notifier);

    final deleted = await notifier.delete('t1');

    expect(deleted, isNotNull);
    expect(trash.entries, hasLength(1));
    expect(await notifier.undo(deleted!), isTrue);

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

  test('undo devuelve el borrado que se le da, no el último de las tareas',
      () async {
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
    final container =
        await loaded([buildTodo(id: 't1'), buildTodo(id: 't2')]);
    final notifier = container.read(todosProvider('L1').notifier);
    final first = await notifier.delete('t1');
    await notifier.delete('t2');

    expect(await notifier.undo(first!), isTrue);

    final restored = verify(() => repo.restoreTodo(
          uid: 'u1',
          listId: 'L1',
          todo: captureAny(named: 'todo'),
        )).captured.single as Todo;
    expect(restored.id, 't1');
    // La otra sigue en la papelera.
    expect(trash.entries.map((e) => e.itemId), ['t2']);
  });

  test('si el borrado falla, delete devuelve null y no deja copia', () async {
    when(() => repo.deleteTodo(uid: 'u1', listId: 'L1', id: 't1'))
        .thenAnswer((_) async => const Err<void>(ServerFailure('Error 500')));
    final container = await loaded([buildTodo(id: 't1')]);

    final deleted =
        await container.read(todosProvider('L1').notifier).delete('t1');

    expect(deleted, isNull);
    expect(trash.entries, isEmpty);
  });

  test('si no se puede guardar la copia, delete no borra la tarea', () async {
    registerFallbackValue(<TrashItem>[]);
    final trashRepo = _MockTrash();
    when(() => trashRepo.save(
          uid: any(named: 'uid'),
          items: any(named: 'items'),
        )).thenAnswer((_) async => const Err(NetworkFailure()));
    final controller = StreamController<List<Todo>>();
    when(() => repo.watchTodos(uid: 'u1', listId: 'L1'))
        .thenAnswer((_) => controller.stream);
    final container = createTestContainer(
      authedUser: buildAuthUser(),
      repositoryOverrides: {TodosRepository: repo},
      extra: [trashRepositoryProvider.overrideWithValue(trashRepo)],
    );
    addTearDown(controller.close);
    expect(container.read(todosProvider('L1')), isA<TodosLoading>());
    controller.add([buildTodo(id: 't1')]);
    await pumpEventQueue();

    final deleted =
        await container.read(todosProvider('L1').notifier).delete('t1');

    expect(deleted, isNull);
    verifyNever(() => repo.deleteTodo(
          uid: any(named: 'uid'),
          listId: any(named: 'listId'),
          id: any(named: 'id'),
        ));
  });

  test('delete de una tarea que no está cargada no borra nada', () async {
    final container = await loaded([buildTodo(id: 't1')]);

    final deleted =
        await container.read(todosProvider('L1').notifier).delete('otra');

    expect(deleted, isNull);
    verifyNever(() => repo.deleteTodo(
          uid: any(named: 'uid'),
          listId: any(named: 'listId'),
          id: any(named: 'id'),
        ));
  });

  test('undo dice que no si la restauración falla', () async {
    when(() => repo.deleteTodo(uid: 'u1', listId: 'L1', id: 't1'))
        .thenAnswer((_) async => const Ok(null));
    when(() => repo.restoreTodo(
          uid: 'u1',
          listId: 'L1',
          todo: any(named: 'todo'),
        )).thenAnswer((_) async => const Err<Todo>(ServerFailure('Error 500')));
    final container = await loaded([buildTodo(id: 't1')]);
    final notifier = container.read(todosProvider('L1').notifier);
    final deleted = await notifier.delete('t1');

    expect(await notifier.undo(deleted!), isFalse);

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
