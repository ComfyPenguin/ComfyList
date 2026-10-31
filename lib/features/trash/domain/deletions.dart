import '../../../shared/core/result/result.dart';
import '../../appointments/domain/entities/appointment.dart';
import '../../appointments/domain/repositories/appointments_repository.dart';
import '../../todo_lists/domain/entities/todo_list.dart';
import '../../todo_lists/domain/repositories/todo_lists_repository.dart';
import '../../todos/domain/entities/todo.dart';
import '../../todos/domain/repositories/todos_repository.dart';
import 'entities/trash_entry.dart';
import 'entities/trash_group.dart';
import 'repositories/trash_repository.dart';

/// Borrar con copia y devolver lo borrado.
///
/// Un borrado primero se guarda en la papelera y solo después se borra: si no
/// hay copia, no se borra, y si el borrado falla, la copia se retira. Lo que
/// devuelve cada `delete*` es el [TrashGroup] recién guardado, y es lo que hay
/// que pasar a [restore] para deshacerlo: se deshace ese borrado, no «el último
/// de su tipo».
class Deletions {
  Deletions({
    required TrashRepository trash,
    required TodosRepository todos,
    required TodoListsRepository lists,
    required AppointmentsRepository appointments,
  })  : _trash = trash,
        _todos = todos,
        _lists = lists,
        _appointments = appointments;

  final TrashRepository _trash;
  final TodosRepository _todos;
  final TodoListsRepository _lists;
  final AppointmentsRepository _appointments;

  Future<Result<TrashGroup>> deleteTodo({
    required String uid,
    required String listId,
    required Todo todo,
  }) =>
      _delete(
        uid: uid,
        items: [_todoItem(todo, listId)],
        remove: () => _todos.deleteTodo(uid: uid, listId: listId, id: todo.id),
      );

  Future<Result<TrashGroup>> deleteAppointment({
    required String uid,
    required Appointment appointment,
  }) =>
      _delete(
        uid: uid,
        items: [
          TrashItem(
            kind: TrashKind.appointment,
            itemId: appointment.id,
            label: appointment.title,
            payload: appointment.toJson(),
          ),
        ],
        remove: () =>
            _appointments.deleteAppointment(uid: uid, id: appointment.id),
      );

  /// Borra [list] con sus tareas. Las tareas se leen antes, porque el borrado
  /// de la lista se las lleva en cascada: si no se pueden leer, no se borra
  /// nada.
  Future<Result<TrashGroup>> deleteList({
    required String uid,
    required TodoList list,
  }) async {
    final read = await _todos.fetchTodos(uid: uid, listId: list.id);
    final List<Todo> todos;
    switch (read) {
      case Ok(:final value):
        todos = value;
      case Err(:final failure):
        return Err(failure);
    }

    return _delete(
      uid: uid,
      items: [
        TrashItem(
          kind: TrashKind.list,
          itemId: list.id,
          label: list.name,
          payload: list.toJson(),
        ),
        for (final todo in todos) _todoItem(todo, list.id),
      ],
      remove: () => _lists.deleteList(
        uid: uid,
        id: list.id,
        todoIds: [for (final todo in todos) todo.id],
      ),
    );
  }

  /// Devuelve [group] a su sitio y lo saca de la papelera. Vale para deshacer
  /// un borrado recién hecho y para restaurar desde la papelera. Una lista
  /// vuelve con sus tareas en una sola escritura. Devuelve si pudo restaurarlo;
  /// quitarlo de la papelera es best-effort y no cambia el resultado.
  Future<bool> restore(TrashGroup group) async {
    if (!await _restoreEntries(group)) return false;

    await _trash.remove(
      uid: group.header.uid,
      ids: [for (final entry in group.entries) entry.id],
    );
    return true;
  }

  Future<Result<TrashGroup>> _delete({
    required String uid,
    required List<TrashItem> items,
    required Future<Result<void>> Function() remove,
  }) async {
    final saved = await _trash.save(uid: uid, items: items);
    final List<TrashEntry> entries;
    switch (saved) {
      case Ok(:final value):
        entries = value;
      case Err(:final failure):
        return Err(failure);
    }

    final removed = await remove();
    if (removed case Err(:final failure)) {
      // La copia sobra: lo que se quiso borrar sigue en su sitio.
      await _trash.remove(
        uid: uid,
        ids: [for (final entry in entries) entry.id],
      );
      return Err(failure);
    }
    return Ok(TrashGroup.partition(entries).single);
  }

  Future<bool> _restoreEntries(TrashGroup group) async {
    final listEntry =
        group.entries.where((e) => e.kind == TrashKind.list).firstOrNull;
    if (listEntry == null) {
      for (final entry in group.entries) {
        if (!await _restoreEntry(entry)) return false;
      }
      return true;
    }

    bool isChild(TrashEntry e) =>
        e.kind == TrashKind.todo && e.parentId == listEntry.itemId;
    final res = await _lists.restoreList(
      uid: listEntry.uid,
      list: TodoList.fromJson(listEntry.payload),
      todos: [
        for (final entry in group.entries)
          if (isChild(entry)) Todo.fromJson(entry.payload),
      ],
    );
    if (res.isErr) return false;
    await _todos.refresh(uid: listEntry.uid, listId: listEntry.itemId);

    for (final entry in group.entries) {
      if (entry != listEntry && !isChild(entry) && !await _restoreEntry(entry)) {
        return false;
      }
    }
    return true;
  }

  Future<bool> _restoreEntry(TrashEntry entry) async {
    switch (entry.kind) {
      case TrashKind.list:
        final res = await _lists.restoreList(
          uid: entry.uid,
          list: TodoList.fromJson(entry.payload),
          todos: const [],
        );
        return res.isOk;

      case TrashKind.todo:
        final listId = entry.parentId;
        if (listId == null) return false;
        final res = await _todos.restoreTodo(
          uid: entry.uid,
          listId: listId,
          todo: Todo.fromJson(entry.payload),
        );
        return res.isOk;

      case TrashKind.appointment:
        final res = await _appointments.restoreAppointment(
          uid: entry.uid,
          appointment: Appointment.fromJson(entry.payload),
        );
        return res.isOk;
    }
  }

  TrashItem _todoItem(Todo todo, String listId) => TrashItem(
        kind: TrashKind.todo,
        itemId: todo.id,
        parentId: listId,
        label: todo.title,
        payload: todo.toJson(),
      );
}
