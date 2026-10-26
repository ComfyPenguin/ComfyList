import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../appointments/domain/entities/appointment.dart';
import '../../../appointments/presentation/providers/appointments_provider.dart';
import '../../../todo_lists/domain/entities/todo_list.dart';
import '../../../todo_lists/presentation/providers/todo_lists_provider.dart';
import '../../../todos/domain/entities/todo.dart';
import '../../../todos/presentation/providers/todos_provider.dart';
import '../../domain/entities/trash_entry.dart';
import '../../domain/entities/trash_group.dart';

/// Devuelve a Firestore lo que hay en la papelera.
///
/// El documento lo escribe el repositorio de su feature — el dato vive allí —
/// así que aquí solo se reparte.
class TrashRestorer {
  TrashRestorer(this._ref);

  final Ref _ref;

  /// Devuelve un borrado entero: una lista vuelve con sus tareas en una sola
  /// escritura.
  Future<bool> restoreGroup(TrashGroup group) async {
    final listEntry =
        group.entries.where((e) => e.kind == TrashKind.list).firstOrNull;
    if (listEntry == null) {
      for (final entry in group.entries) {
        if (!await restore(entry)) return false;
      }
      return true;
    }

    bool isChild(TrashEntry e) =>
        e.kind == TrashKind.todo && e.parentId == listEntry.itemId;
    final res = await _ref.read(todoListsRepositoryProvider).restoreList(
          uid: listEntry.uid,
          list: TodoList.fromJson(listEntry.payload),
          todos: [
            for (final entry in group.entries)
              if (isChild(entry)) Todo.fromJson(entry.payload),
          ],
        );
    if (res.isErr) return false;
    await _ref
        .read(todosRepositoryProvider)
        .refresh(uid: listEntry.uid, listId: listEntry.itemId);

    for (final entry in group.entries) {
      if (entry != listEntry && !isChild(entry) && !await restore(entry)) {
        return false;
      }
    }
    return true;
  }

  Future<bool> restore(TrashEntry entry) async {
    switch (entry.kind) {
      case TrashKind.list:
        final res = await _ref.read(todoListsRepositoryProvider).restoreList(
              uid: entry.uid,
              list: TodoList.fromJson(entry.payload),
              todos: const [],
            );
        return res.isOk;

      case TrashKind.todo:
        return _restoreTodo(entry);

      case TrashKind.appointment:
        final res =
            await _ref.read(appointmentsRepositoryProvider).restoreAppointment(
                  uid: entry.uid,
                  appointment: Appointment.fromJson(entry.payload),
                );
        return res.isOk;
    }
  }

  Future<bool> _restoreTodo(TrashEntry entry) async {
    final listId = entry.parentId;
    if (listId == null) return false;

    final res = await _ref.read(todosRepositoryProvider).restoreTodo(
          uid: entry.uid,
          listId: listId,
          todo: Todo.fromJson(entry.payload),
        );
    return res.isOk;
  }
}

final trashRestorerProvider = Provider<TrashRestorer>(TrashRestorer.new);
