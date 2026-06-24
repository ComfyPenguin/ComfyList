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
}
