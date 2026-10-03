import '../../../../shared/core/result/result.dart';
import '../entities/todo.dart';

abstract class TodosRepository {
  /// Stream que emite la lista actual de todos de una [listId] concreta.
  /// La implementación REST hace polling cada 15s + emite tras cada mutación.
  Stream<List<Todo>> watchTodos({
    required String uid,
    required String listId,
  });

  Future<Result<List<Todo>>> fetchTodos({
    required String uid,
    required String listId,
  });

  Future<Result<Todo>> createTodo({
    required String uid,
    required String listId,
    required String title,
    String? description,
  });

  Future<Result<Todo>> updateTodo({
    required String uid,
    required String listId,
    required String id,
    String? title,
    String? description,
    bool clearDescription = false,
    bool? isDone,
  });

  Future<Result<void>> deleteTodo({
    required String uid,
    required String listId,
    required String id,
  });

  /// Devuelve [todo] a Firestore con su mismo id, para deshacer el borrado.
  Future<Result<Todo>> restoreTodo({
    required String uid,
    required String listId,
    required Todo todo,
  });

  /// Pausa el polling de watchers activos. Llamado al pasar la app a
  /// background para ahorrar batería y evitar errores de socket.
  void pauseAll();

  /// Reactiva el polling (con fetch inmediato) en todos los watchers
  /// previamente pausados. Llamado al volver la app a foreground.
  void resumeAll();
}
