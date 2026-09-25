import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/core/failures/failure.dart';
import '../../../../shared/core/time/clock.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/providers/auth_state.dart';
import '../../../todos/domain/entities/todo.dart';
import '../../../todos/presentation/providers/todos_provider.dart';
import '../../data/datasources/firestore_lists_remote.dart';
import '../../data/repositories/todo_lists_repository_impl.dart';
import '../../domain/entities/todo_list.dart';
import '../../domain/repositories/todo_lists_repository.dart';
import 'todo_lists_state.dart';

final firestoreListsRemoteProvider = Provider<FirestoreListsRemote>((ref) {
  return FirestoreListsRemote(ref.watch(dioClientProvider).instance);
});

final todoListsRepositoryProvider = Provider<TodoListsRepository>((ref) {
  final repo = TodoListsRepositoryImpl(
    ref.watch(firestoreListsRemoteProvider),
    pollInterval: ref.watch(pollIntervalProvider),
  );
  ref.onDispose(repo.dispose);
  return repo;
});

/// Notifier de listas de tareas. Re-construye al cambiar [authProvider].
class TodoListsNotifier extends Notifier<TodoListsState> {
  StreamSubscription<dynamic>? _sub;

  @override
  TodoListsState build() {
    final auth = ref.watch(authProvider);
    if (auth is! Authenticated) return const TodoListsInitial();

    final uid = auth.user.uid;
    final repo = ref.read(todoListsRepositoryProvider);

    _sub?.cancel();
    _sub = repo.watchLists(uid).listen(
      (items) => state = TodoListsData(items),
      onError: (Object e, StackTrace st) {
        if (state is! TodoListsData) {
          state = TodoListsError(e is Failure ? e : const UnknownFailure());
        }
        // Si ya tenemos datos en pantalla, descartamos el error transitorio
        // (siguiente poll lo arreglará). Evita parpadeo de error tras resume.
      },
    );
    ref.onDispose(() => _sub?.cancel());

    return const TodoListsLoading();
  }

  String get _uid => (ref.read(authProvider) as Authenticated).user.uid;

  Future<void> create({required String name, required String iconKey}) async {
    final res = await ref.read(todoListsRepositoryProvider).createList(
          uid: _uid,
          name: name,
          iconKey: iconKey,
        );
    res.fold(onOk: (_) {}, onErr: (f) => state = TodoListsError(f));
  }

  Future<void> updateFields({
    required String id,
    String? name,
    String? iconKey,
  }) async {
    await ref.read(todoListsRepositoryProvider).updateList(
          uid: _uid,
          id: id,
          name: name,
          iconKey: iconKey,
        );
  }

  /// Última lista borrada, con sus tareas. Solo se puede deshacer esa: el aviso
  /// que ofrece deshacer es único y un borrado nuevo reemplaza al anterior.
  ({TodoList list, List<Todo> todos})? _lastDeleted;

  Future<void> delete(String id) async {
    final list = _findById(id);
    // Las tareas hay que leerlas antes: el borrado se las lleva en cascada.
    final todos = await _todosOf(id);

    await ref.read(todoListsRepositoryProvider).deleteList(uid: _uid, id: id);
    if (list != null) _lastDeleted = (list: list, todos: todos);
  }

  /// Devuelve la última lista borrada junto con sus tareas. Devuelve si se pudo.
  Future<bool> undoLastDelete() async {
    final deleted = _lastDeleted;
    if (deleted == null) return false;

    final res = await ref.read(todoListsRepositoryProvider).restoreList(
          uid: _uid,
          list: deleted.list,
        );
    if (res.isErr) return false;

    final todosRepo = ref.read(todosRepositoryProvider);
    for (final todo in deleted.todos) {
      final restored = await todosRepo.restoreTodo(
        uid: _uid,
        listId: deleted.list.id,
        todo: todo,
      );
      if (restored.isErr) return false;
    }

    _lastDeleted = null;
    return true;
  }

  Future<List<Todo>> _todosOf(String listId) async {
    final res = await ref.read(todosRepositoryProvider).fetchTodos(
          uid: _uid,
          listId: listId,
        );
    return res.fold(onOk: (items) => items, onErr: (_) => const <Todo>[]);
  }

  TodoList? _findById(String id) {
    final current = state;
    if (current is! TodoListsData) return null;
    for (final list in current.items) {
      if (list.id == id) return list;
    }
    return null;
  }
}

final todoListsProvider =
    NotifierProvider<TodoListsNotifier, TodoListsState>(TodoListsNotifier.new);
