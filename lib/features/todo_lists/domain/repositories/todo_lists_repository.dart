import '../../../../shared/core/result/result.dart';
import '../entities/todo_list.dart';

abstract class TodoListsRepository {
  /// Stream con la colección de listas del usuario.
  /// La implementación REST hace polling + emite tras cada mutación.
  Stream<List<TodoList>> watchLists(String uid);

  Future<Result<List<TodoList>>> fetchLists(String uid);

  Future<Result<TodoList>> createList({
    required String uid,
    required String name,
    required String iconKey,
  });

  Future<Result<TodoList>> updateList({
    required String uid,
    required String id,
    String? name,
    String? iconKey,
  });

  /// Borra la lista. La implementación se encarga de borrar en cascada
  /// los todos de la subcolección — Firestore no lo hace automáticamente.
  Future<Result<void>> deleteList({
    required String uid,
    required String id,
  });

  /// Devuelve [list] a Firestore con su mismo id, para deshacer el borrado.
  /// Sus tareas las restaura quien orquesta el deshacer: viven en la
  /// subcolección que gestiona el feature `todos`.
  Future<Result<TodoList>> restoreList({
    required String uid,
    required TodoList list,
  });

  /// Pausa el polling de watchers activos. Llamado al pasar la app a
  /// background para ahorrar batería y evitar errores de socket.
  void pauseAll();

  /// Reactiva el polling (con fetch inmediato) en todos los watchers
  /// previamente pausados. Llamado al volver la app a foreground.
  void resumeAll();
}
