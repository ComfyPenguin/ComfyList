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

  /// Devuelve un borrado entero: una lista vuelve con sus tareas. El grupo ya
  /// trae la lista delante, que es de quien cuelgan.
  Future<bool> restoreGroup(TrashGroup group) async {
    for (final entry in group.entries) {
      if (!await restore(entry)) return false;
    }
    return true;
  }

  Future<bool> restore(TrashEntry entry) async {
    switch (entry.kind) {
      case TrashKind.list:
        final res = await _ref.read(todoListsRepositoryProvider).restoreList(
              uid: entry.uid,
              list: TodoList.fromJson(entry.payload),
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
