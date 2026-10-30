import 'package:comfy_list/features/appointments/domain/repositories/appointments_repository.dart';
import 'package:comfy_list/features/todo_lists/domain/repositories/todo_lists_repository.dart';
import 'package:comfy_list/features/todos/domain/entities/todo.dart';
import 'package:comfy_list/features/todos/domain/repositories/todos_repository.dart';
import 'package:comfy_list/features/trash/domain/deletions.dart';
import 'package:comfy_list/features/trash/domain/entities/trash_entry.dart';
import 'package:comfy_list/features/trash/domain/entities/trash_group.dart';
import 'package:comfy_list/features/trash/domain/repositories/trash_repository.dart';
import 'package:comfy_list/shared/core/failures/failure.dart';
import 'package:comfy_list/shared/core/result/result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/test_helpers.dart';

class _MockTrash extends Mock implements TrashRepository {}

class _MockTodos extends Mock implements TodosRepository {}

class _MockLists extends Mock implements TodoListsRepository {}

class _MockAppointments extends Mock implements AppointmentsRepository {}

void main() {
  late _MockTrash trash;
  late _MockTodos todos;
  late _MockLists lists;
  late _MockAppointments appointments;
  late Deletions deletions;

  setUpAll(() {
    registerFallbackValue(<TrashItem>[]);
    registerFallbackValue(<String>[]);
    registerFallbackValue(buildTodo());
    registerFallbackValue(<Todo>[]);
    registerFallbackValue(buildTodoList());
    registerFallbackValue(buildAppointment());
  });

  final deletedAt = DateTime.utc(2026, 6, 1);

  TrashEntry entryOf(TrashItem item, int index, {String groupId = 'g1'}) =>
      TrashEntry(
        id: 'r$index',
        uid: 'u1',
        groupId: groupId,
        item: item,
        deletedAt: deletedAt,
      );

  setUp(() {
    trash = _MockTrash();
    todos = _MockTodos();
    lists = _MockLists();
    appointments = _MockAppointments();
    deletions = Deletions(
      trash: trash,
      todos: todos,
      lists: lists,
      appointments: appointments,
    );

    // Por defecto, guardar en la papelera sale bien y devuelve una fila por
    // elemento.
    when(() => trash.save(
          uid: any(named: 'uid'),
          items: any(named: 'items'),
        )).thenAnswer((invocation) async {
      final items = invocation.namedArguments[#items] as List<TrashItem>;
      return Ok([
        for (final (index, item) in items.indexed) entryOf(item, index),
      ]);
    });
    when(() => trash.remove(
          uid: any(named: 'uid'),
          ids: any(named: 'ids'),
        )).thenAnswer((_) async => const Ok(null));
    when(() => todos.refresh(
          uid: any(named: 'uid'),
          listId: any(named: 'listId'),
        )).thenAnswer((_) async {});
  });

  Failure failureOf<T>(Result<T> res) =>
      res.fold(onOk: (_) => fail('Se esperaba Err'), onErr: (f) => f);

  TrashGroup groupOf<T>(Result<TrashGroup> res) =>
      res.fold(onOk: (g) => g, onErr: (f) => fail('Err: $f'));

  group('deleteTodo', () {
    setUp(() {
      when(() => todos.deleteTodo(
            uid: any(named: 'uid'),
            listId: any(named: 'listId'),
            id: any(named: 'id'),
          )).thenAnswer((_) async => const Ok(null));
    });

    test('guarda la copia antes de borrar y devuelve ese borrado', () async {
      final res = await deletions.deleteTodo(
        uid: 'u1',
        listId: 'L1',
        todo: buildTodo(id: 't1', title: 'Pan'),
      );

      verifyInOrder([
        () => trash.save(uid: 'u1', items: any(named: 'items')),
        () => todos.deleteTodo(uid: 'u1', listId: 'L1', id: 't1'),
      ]);
      final group = groupOf(res);
      expect(group.kind, TrashKind.todo);
      expect(group.header.itemId, 't1');
      expect(group.header.parentId, 'L1');
      expect(group.header.label, 'Pan');
    });

    test('si no se puede guardar la copia, no borra', () async {
      when(() => trash.save(
            uid: any(named: 'uid'),
            items: any(named: 'items'),
          )).thenAnswer((_) async => const Err(NetworkFailure()));

      final res = await deletions.deleteTodo(
        uid: 'u1',
        listId: 'L1',
        todo: buildTodo(),
      );

      expect(failureOf(res), isA<NetworkFailure>());
      verifyNever(() => todos.deleteTodo(
            uid: any(named: 'uid'),
            listId: any(named: 'listId'),
            id: any(named: 'id'),
          ));
    });

    test('si el borrado falla, retira la copia y devuelve el fallo', () async {
      when(() => todos.deleteTodo(
            uid: any(named: 'uid'),
            listId: any(named: 'listId'),
            id: any(named: 'id'),
          )).thenAnswer((_) async => const Err(ServerFailure('500')));

      final res = await deletions.deleteTodo(
        uid: 'u1',
        listId: 'L1',
        todo: buildTodo(),
      );

      expect(failureOf(res), isA<ServerFailure>());
      verify(() => trash.remove(uid: 'u1', ids: ['r0'])).called(1);
    });
  });

  group('deleteAppointment', () {
    test('guarda la copia, borra y devuelve ese borrado', () async {
      when(() => appointments.deleteAppointment(
            uid: any(named: 'uid'),
            id: any(named: 'id'),
          )).thenAnswer((_) async => const Ok(null));

      final res = await deletions.deleteAppointment(
        uid: 'u1',
        appointment: buildAppointment(id: 'a1', title: 'Dentista'),
      );

      verifyInOrder([
        () => trash.save(uid: 'u1', items: any(named: 'items')),
        () => appointments.deleteAppointment(uid: 'u1', id: 'a1'),
      ]);
      final group = groupOf(res);
      expect(group.kind, TrashKind.appointment);
      expect(group.header.label, 'Dentista');
    });

    test('si el borrado falla, retira la copia', () async {
      when(() => appointments.deleteAppointment(
            uid: any(named: 'uid'),
            id: any(named: 'id'),
          )).thenAnswer((_) async => const Err(NetworkFailure()));

      final res = await deletions.deleteAppointment(
        uid: 'u1',
        appointment: buildAppointment(),
      );

      expect(res.isErr, isTrue);
      verify(() => trash.remove(uid: 'u1', ids: ['r0'])).called(1);
    });
  });

  group('deleteList', () {
    test('lee las tareas antes, las guarda con la lista y borra todo', () async {
      when(() => todos.fetchTodos(uid: 'u1', listId: 'L1')).thenAnswer(
        (_) async => Ok([buildTodo(id: 't1'), buildTodo(id: 't2')]),
      );
      when(() => lists.deleteList(
            uid: any(named: 'uid'),
            id: any(named: 'id'),
            todoIds: any(named: 'todoIds'),
          )).thenAnswer((_) async => const Ok(null));

      final res = await deletions.deleteList(
        uid: 'u1',
        list: buildTodoList(id: 'L1', name: 'Compra'),
      );

      verifyInOrder([
        () => todos.fetchTodos(uid: 'u1', listId: 'L1'),
        () => trash.save(uid: 'u1', items: any(named: 'items')),
        () => lists.deleteList(uid: 'u1', id: 'L1', todoIds: ['t1', 't2']),
      ]);
      final group = groupOf(res);
      expect(group.kind, TrashKind.list);
      expect(group.header.label, 'Compra');
      expect(group.contents.map((e) => e.itemId), ['t1', 't2']);
      expect(group.contents.every((e) => e.parentId == 'L1'), isTrue);
    });

    test('si no puede leer las tareas, no guarda ni borra nada', () async {
      when(() => todos.fetchTodos(uid: 'u1', listId: 'L1'))
          .thenAnswer((_) async => const Err(NetworkFailure()));

      final res = await deletions.deleteList(
        uid: 'u1',
        list: buildTodoList(id: 'L1'),
      );

      expect(failureOf(res), isA<NetworkFailure>());
      verifyNever(() => trash.save(
            uid: any(named: 'uid'),
            items: any(named: 'items'),
          ));
      verifyNever(() => lists.deleteList(
            uid: any(named: 'uid'),
            id: any(named: 'id'),
            todoIds: any(named: 'todoIds'),
          ));
    });

    test('si el borrado falla, retira la copia de la lista y de sus tareas',
        () async {
      when(() => todos.fetchTodos(uid: 'u1', listId: 'L1'))
          .thenAnswer((_) async => Ok([buildTodo(id: 't1')]));
      when(() => lists.deleteList(
            uid: any(named: 'uid'),
            id: any(named: 'id'),
            todoIds: any(named: 'todoIds'),
          )).thenAnswer((_) async => const Err(NetworkFailure()));

      final res = await deletions.deleteList(
        uid: 'u1',
        list: buildTodoList(id: 'L1'),
      );

      expect(res.isErr, isTrue);
      verify(() => trash.remove(uid: 'u1', ids: ['r0', 'r1'])).called(1);
    });
  });

  group('restore', () {
    TrashGroup groupFrom(List<TrashItem> items) => TrashGroup.partition([
          for (final (index, item) in items.indexed) entryOf(item, index),
        ]).single;

    test('devuelve una tarea y la saca de la papelera', () async {
      when(() => todos.restoreTodo(
            uid: any(named: 'uid'),
            listId: any(named: 'listId'),
            todo: any(named: 'todo'),
          )).thenAnswer((_) async => Ok(buildTodo(id: 't1')));
      final todo = buildTodo(id: 't1');

      final ok = await deletions.restore(groupFrom([
        TrashItem(
          kind: TrashKind.todo,
          itemId: 't1',
          parentId: 'L1',
          label: 'Pan',
          payload: todo.toJson(),
        ),
      ]));

      expect(ok, isTrue);
      verify(() => todos.restoreTodo(
            uid: 'u1',
            listId: 'L1',
            todo: any(named: 'todo'),
          )).called(1);
      verify(() => trash.remove(uid: 'u1', ids: ['r0'])).called(1);
    });

    test('devuelve una lista con sus tareas en una sola escritura', () async {
      when(() => lists.restoreList(
            uid: any(named: 'uid'),
            list: any(named: 'list'),
            todos: any(named: 'todos'),
          )).thenAnswer((_) async => const Ok(null));

      final ok = await deletions.restore(groupFrom([
        TrashItem(
          kind: TrashKind.list,
          itemId: 'L1',
          label: 'Compra',
          payload: buildTodoList(id: 'L1').toJson(),
        ),
        TrashItem(
          kind: TrashKind.todo,
          itemId: 't1',
          parentId: 'L1',
          label: 'Pan',
          payload: buildTodo(id: 't1').toJson(),
        ),
      ]));

      expect(ok, isTrue);
      final sent = verify(() => lists.restoreList(
            uid: 'u1',
            list: any(named: 'list'),
            todos: captureAny(named: 'todos'),
          )).captured.single as List<Todo>;
      expect(sent.map((t) => t.id), ['t1']);
      verify(() => todos.refresh(uid: 'u1', listId: 'L1')).called(1);
      verify(() => trash.remove(uid: 'u1', ids: ['r0', 'r1'])).called(1);
    });

    test('devuelve una cita', () async {
      when(() => appointments.restoreAppointment(
            uid: any(named: 'uid'),
            appointment: any(named: 'appointment'),
          )).thenAnswer((_) async => Ok(buildAppointment(id: 'a1')));

      final ok = await deletions.restore(groupFrom([
        TrashItem(
          kind: TrashKind.appointment,
          itemId: 'a1',
          label: 'Dentista',
          payload: buildAppointment(id: 'a1').toJson(),
        ),
      ]));

      expect(ok, isTrue);
    });

    test('si no puede restaurar, no toca la papelera', () async {
      when(() => todos.restoreTodo(
            uid: any(named: 'uid'),
            listId: any(named: 'listId'),
            todo: any(named: 'todo'),
          )).thenAnswer((_) async => const Err(NetworkFailure()));

      final ok = await deletions.restore(groupFrom([
        TrashItem(
          kind: TrashKind.todo,
          itemId: 't1',
          parentId: 'L1',
          label: 'Pan',
          payload: buildTodo(id: 't1').toJson(),
        ),
      ]));

      expect(ok, isFalse);
      verifyNever(() => trash.remove(
            uid: any(named: 'uid'),
            ids: any(named: 'ids'),
          ));
    });

    test('una tarea sin lista no se puede restaurar', () async {
      final ok = await deletions.restore(groupFrom([
        TrashItem(
          kind: TrashKind.todo,
          itemId: 't1',
          label: 'Pan',
          payload: buildTodo(id: 't1').toJson(),
        ),
      ]));

      expect(ok, isFalse);
      verifyNever(() => trash.remove(
            uid: any(named: 'uid'),
            ids: any(named: 'ids'),
          ));
    });

    test('si quitarlo de la papelera falla, igualmente cuenta como restaurado',
        () async {
      when(() => appointments.restoreAppointment(
            uid: any(named: 'uid'),
            appointment: any(named: 'appointment'),
          )).thenAnswer((_) async => Ok(buildAppointment(id: 'a1')));
      when(() => trash.remove(
            uid: any(named: 'uid'),
            ids: any(named: 'ids'),
          )).thenAnswer((_) async => const Err(NetworkFailure()));

      final ok = await deletions.restore(groupFrom([
        TrashItem(
          kind: TrashKind.appointment,
          itemId: 'a1',
          label: 'Dentista',
          payload: buildAppointment(id: 'a1').toJson(),
        ),
      ]));

      expect(ok, isTrue);
    });
  });
}
