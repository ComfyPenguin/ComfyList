import 'package:comfy_list/features/appointments/domain/entities/appointment.dart';
import 'package:comfy_list/features/appointments/domain/repositories/appointments_repository.dart';
import 'package:comfy_list/features/todo_lists/domain/entities/todo_list.dart';
import 'package:comfy_list/features/todo_lists/domain/repositories/todo_lists_repository.dart';
import 'package:comfy_list/features/todos/domain/entities/todo.dart';
import 'package:comfy_list/features/todos/domain/repositories/todos_repository.dart';
import 'package:comfy_list/features/trash/domain/entities/trash_entry.dart';
import 'package:comfy_list/features/trash/domain/entities/trash_group.dart';
import 'package:comfy_list/features/trash/presentation/providers/trash_restore.dart';
import 'package:comfy_list/shared/core/failures/failure.dart';
import 'package:comfy_list/shared/core/result/result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/provider_scope.dart';
import '../../../../helpers/test_helpers.dart';

class _MockListsRepo extends Mock implements TodoListsRepository {}

class _MockTodosRepo extends Mock implements TodosRepository {}

class _MockAppointmentsRepo extends Mock implements AppointmentsRepository {}

void main() {
  late _MockListsRepo listsRepo;
  late _MockTodosRepo todosRepo;
  late _MockAppointmentsRepo appointmentsRepo;

  setUpAll(() {
    // mocktail necesita un valor de relleno para los matchers de entidades.
    registerFallbackValue(buildTodoList());
    registerFallbackValue(buildTodo());
    registerFallbackValue(<Todo>[]);
    registerFallbackValue(buildAppointment());
  });

  setUp(() {
    listsRepo = _MockListsRepo();
    todosRepo = _MockTodosRepo();
    when(() => todosRepo.refresh(
          uid: any(named: 'uid'),
          listId: any(named: 'listId'),
        )).thenAnswer((_) async {});
    appointmentsRepo = _MockAppointmentsRepo();
  });

  ProviderContainer container() => createTestContainer(
        authedUser: buildAuthUser(),
        repositoryOverrides: {
          TodoListsRepository: listsRepo,
          TodosRepository: todosRepo,
          AppointmentsRepository: appointmentsRepo,
        },
      );

  TrashEntry entry({
    required TrashKind kind,
    String id = 'x1',
    String entryId = 'e1',
    String? parentId,
    Map<String, dynamic> payload = const {},
  }) {
    return TrashEntry(
      id: entryId,
      uid: 'u1',
      groupId: 'g1',
      deletedAt: DateTime.now().toUtc(),
      item: TrashItem(
        kind: kind,
        itemId: id,
        parentId: parentId,
        label: 'algo',
        payload: payload,
      ),
    );
  }

  test('una lista vuelve por el repositorio de listas', () async {
    final list = buildTodoList(id: 'L1', name: 'Compras');
    when(() => listsRepo.restoreList(
          uid: 'u1',
          list: any(named: 'list'),
          todos: any(named: 'todos'),
        ))
        .thenAnswer((_) async => const Ok(null));

    final restored = await container().read(trashRestorerProvider).restore(
          entry(kind: TrashKind.list, id: 'L1', payload: list.toJson()),
        );

    expect(restored, isTrue);
    final sent = verify(() => listsRepo.restoreList(
          uid: 'u1',
          list: captureAny(named: 'list'),
          todos: any(named: 'todos'),
        )).captured.single as TodoList;
    expect(sent.id, 'L1');
    expect(sent.name, 'Compras');
  });

  test('una tarea vuelve a su lista, no a la que se esté viendo', () async {
    final todo = buildTodo(id: 't1', title: 'Comprar pan');
    when(() => todosRepo.restoreTodo(
          uid: 'u1',
          listId: any(named: 'listId'),
          todo: any(named: 'todo'),
        )).thenAnswer((_) async => Ok(todo));

    final restored = await container().read(trashRestorerProvider).restore(
          entry(
            kind: TrashKind.todo,
            id: 't1',
            parentId: 'L9',
            payload: todo.toJson(),
          ),
        );

    expect(restored, isTrue);
    final sent = verify(() => todosRepo.restoreTodo(
          uid: 'u1',
          listId: captureAny(named: 'listId'),
          todo: captureAny(named: 'todo'),
        )).captured;
    expect(sent.first, 'L9');
    expect((sent.last as Todo).title, 'Comprar pan');
  });

  test('una cita vuelve por el repositorio de citas', () async {
    final appointment = buildAppointment(id: 'a1', title: 'Dentista');
    when(() => appointmentsRepo.restoreAppointment(
          uid: 'u1',
          appointment: any(named: 'appointment'),
        )).thenAnswer((_) async => Ok(appointment));

    final restored = await container().read(trashRestorerProvider).restore(
          entry(
            kind: TrashKind.appointment,
            id: 'a1',
            payload: appointment.toJson(),
          ),
        );

    expect(restored, isTrue);
    final sent = verify(() => appointmentsRepo.restoreAppointment(
          uid: 'u1',
          appointment: captureAny(named: 'appointment'),
        )).captured.single as Appointment;
    expect(sent.title, 'Dentista');
  });

  test('una tarea sin lista no se puede devolver', () async {
    final restored = await container().read(trashRestorerProvider).restore(
          entry(kind: TrashKind.todo, id: 't1'),
        );

    expect(restored, isFalse);
    verifyNever(() => todosRepo.restoreTodo(
          uid: any(named: 'uid'),
          listId: any(named: 'listId'),
          todo: any(named: 'todo'),
        ));
  });

  test('si la escritura falla, la restauración dice que no', () async {
    final todo = buildTodo(id: 't1');
    when(() => todosRepo.restoreTodo(
          uid: 'u1',
          listId: 'L1',
          todo: any(named: 'todo'),
        )).thenAnswer(
      (_) async => const Err<Todo>(ServerFailure('Error 500')),
    );

    final restored = await container().read(trashRestorerProvider).restore(
          entry(
            kind: TrashKind.todo,
            id: 't1',
            parentId: 'L1',
            payload: todo.toJson(),
          ),
        );

    expect(restored, isFalse);
  });

  test('el grupo de una lista la devuelve con sus tareas de una vez',
      () async {
    final list = buildTodoList(id: 'L1');
    final todo = buildTodo(id: 't1');

    when(() => listsRepo.restoreList(
          uid: 'u1',
          list: any(named: 'list'),
          todos: any(named: 'todos'),
        ))
        .thenAnswer((_) async => const Ok(null));

    final restored = await container().read(trashRestorerProvider).restoreGroup(
          TrashGroup.partition([
            entry(
              kind: TrashKind.todo,
              id: 't1',
              parentId: 'L1',
              payload: todo.toJson(),
            ),
            entry(kind: TrashKind.list, id: 'L1', payload: list.toJson()),
          ]).single,
        );

    expect(restored, isTrue);
    final todos = verify(
      () => listsRepo.restoreList(
        uid: 'u1',
        list: any(named: 'list'),
        todos: captureAny(named: 'todos'),
      ),
    ).captured.single as List<Todo>;
    expect(todos.map((t) => t.id), ['t1']);
    // Quien esté viendo esa lista recibe las tareas sin esperar al poll.
    verify(() => todosRepo.refresh(uid: 'u1', listId: 'L1')).called(1);
    verifyNever(
      () => todosRepo.restoreTodo(
        uid: any(named: 'uid'),
        listId: any(named: 'listId'),
        todo: any(named: 'todo'),
      ),
    );
  });
}
