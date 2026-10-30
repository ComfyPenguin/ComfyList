import '../../../../shared/core/result/result.dart';
import '../../../todos/domain/entities/todo.dart';
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

  /// Borra la lista junto con las tareas [todoIds] de su subcolección, que
  /// Firestore no borra por sí solo.
  Future<Result<void>> deleteList({
    required String uid,
    required String id,
    required List<String> todoIds,
  });

  /// Devuelve [list] y sus [todos] a Firestore con sus mismos ids, para
  /// deshacer el borrado.
  Future<Result<void>> restoreList({
    required String uid,
    required TodoList list,
    required List<Todo> todos,
  });
}
