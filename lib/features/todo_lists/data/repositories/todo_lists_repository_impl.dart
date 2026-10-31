import '../../../../shared/core/lifecycle/polling_registry.dart';
import '../../../../shared/core/result/result.dart';
import '../../../../shared/core/time/clock.dart';
import '../../../../shared/data/remote/polled_collection.dart';
import '../../../todos/domain/entities/todo.dart';
import '../../domain/entities/todo_list.dart';
import '../../domain/repositories/todo_lists_repository.dart';
import '../datasources/firestore_lists_remote.dart';

/// Implementación REST con polling 15s + refresh inmediato tras mutación,
/// que lleva la [PolledCollection] de listas de cada usuario.
class TodoListsRepositoryImpl implements TodoListsRepository {
  TodoListsRepositoryImpl(
    this._remote, {
    Duration pollInterval = defaultPollInterval,
    PollingRegistry? registry,
  }) : _lists = PolledCollection<String, TodoList>(
          fetch: _remote.listLists,
          interval: pollInterval,
          registry: registry,
        );

  final FirestoreListsRemote _remote;

  final PolledCollection<String, TodoList> _lists;

  @override
  Stream<List<TodoList>> watchLists(String uid) => _lists.watch(uid);

  @override
  Future<Result<List<TodoList>>> fetchLists(String uid) =>
      _lists.read(() => _remote.listLists(uid));

  @override
  Future<Result<TodoList>> createList({
    required String uid,
    required String name,
    required String iconKey,
  }) =>
      _lists.guard(
        uid,
        () => _remote.createList(uid: uid, name: name, iconKey: iconKey),
      );

  @override
  Future<Result<TodoList>> updateList({
    required String uid,
    required String id,
    String? name,
    String? iconKey,
  }) =>
      _lists.guard(
        uid,
        () => _remote.updateList(
          uid: uid,
          id: id,
          name: name,
          iconKey: iconKey,
        ),
      );

  @override
  Future<Result<void>> deleteList({
    required String uid,
    required String id,
    required List<String> todoIds,
  }) =>
      _lists.guard(
        uid,
        () => _remote.deleteListWithTodos(uid: uid, id: id, todoIds: todoIds),
      );

  @override
  Future<Result<void>> restoreList({
    required String uid,
    required TodoList list,
    required List<Todo> todos,
  }) =>
      _lists.guard(
        uid,
        () => _remote.restoreListWithTodos(uid: uid, list: list, todos: todos),
      );

  void dispose() => _lists.dispose();
}
