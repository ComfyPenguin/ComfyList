import '../../../../shared/core/lifecycle/polling_registry.dart';
import '../../../../shared/core/result/result.dart';
import '../../../../shared/core/time/clock.dart';
import '../../../../shared/data/remote/polled_collection.dart';
import '../../domain/entities/todo.dart';
import '../../domain/repositories/todos_repository.dart';
import '../datasources/firestore_rest_remote.dart';

/// Implementación REST con polling 15s + refresh inmediato tras mutación.
///
/// Cada (uid, listId) es una [PolledCollection] independiente: permite tener
/// varias listas abiertas (p. ej. tras navegación rápida) sin que se pisen.
class TodosRepositoryImpl implements TodosRepository {
  TodosRepositoryImpl(
    this._remote, {
    Duration pollInterval = defaultPollInterval,
    PollingRegistry? registry,
  }) : _todos = PolledCollection<(String, String), Todo>(
          fetch: (key) => _remote.listTodos(uid: key.$1, listId: key.$2),
          interval: pollInterval,
          registry: registry,
        );

  final FirestoreRestRemote _remote;

  final PolledCollection<(String, String), Todo> _todos;

  @override
  Stream<List<Todo>> watchTodos({
    required String uid,
    required String listId,
  }) =>
      _todos.watch((uid, listId));

  @override
  Future<void> refresh({required String uid, required String listId}) =>
      _todos.refresh((uid, listId));

  @override
  Future<Result<List<Todo>>> fetchTodos({
    required String uid,
    required String listId,
  }) =>
      _todos.read(() => _remote.listTodos(uid: uid, listId: listId));

  @override
  Future<Result<Todo>> createTodo({
    required String uid,
    required String listId,
    required String title,
    String? description,
  }) =>
      _todos.guard(
        (uid, listId),
        () => _remote.createTodo(
          uid: uid,
          listId: listId,
          title: title,
          description: description,
        ),
      );

  @override
  Future<Result<Todo>> updateTodo({
    required String uid,
    required String listId,
    required String id,
    String? title,
    String? description,
    bool clearDescription = false,
    bool? isDone,
  }) =>
      _todos.guard(
        (uid, listId),
        () => _remote.updateTodo(
          uid: uid,
          listId: listId,
          id: id,
          title: title,
          description: description,
          clearDescription: clearDescription,
          isDone: isDone,
        ),
      );

  @override
  Future<Result<void>> deleteTodo({
    required String uid,
    required String listId,
    required String id,
  }) =>
      _todos.guard(
        (uid, listId),
        () => _remote.deleteTodo(uid: uid, listId: listId, id: id),
      );

  @override
  Future<Result<Todo>> restoreTodo({
    required String uid,
    required String listId,
    required Todo todo,
  }) =>
      _todos.guard(
        (uid, listId),
        () => _remote.restoreTodo(uid: uid, listId: listId, todo: todo),
      );

  void dispose() => _todos.dispose();
}
