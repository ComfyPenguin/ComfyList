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
}
