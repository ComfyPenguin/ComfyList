import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/core/failures/failure.dart';
import '../../../../shared/core/lifecycle/polling_registry.dart';
import '../../../../shared/core/time/clock.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/providers/auth_state.dart';
import '../../../trash/domain/entities/trash_entry.dart';
import '../../../trash/presentation/providers/trash_provider.dart';
import '../../data/datasources/firestore_rest_remote.dart';
import '../../data/repositories/todos_repository_impl.dart';
import '../../domain/entities/todo.dart';
import '../../domain/repositories/todos_repository.dart';
import 'todos_state.dart';

final firestoreRestRemoteProvider = Provider<FirestoreRestRemote>((ref) {
  return FirestoreRestRemote(ref.watch(dioClientProvider).instance);
});

final todosRepositoryProvider = Provider<TodosRepository>((ref) {
  final repo = TodosRepositoryImpl(
    ref.watch(firestoreRestRemoteProvider),
    pollInterval: ref.watch(pollIntervalProvider),
    registry: ref.watch(pollingRegistryProvider),
  );
  ref.onDispose(repo.dispose);
  return repo;
});

/// Notifier de todos por lista. El argumento del family es el `listId`,
/// que se inyecta vía constructor (en Riverpod 3.x `FamilyNotifier` se
/// fusionó con `Notifier`).
/// Cuando el [authProvider] cambia (login/logout), `build` se re-ejecuta
/// y la suscripción al watcher se renueva.
class TodosNotifier extends Notifier<TodosState> {
  TodosNotifier(this._listId);

  final String _listId;
  StreamSubscription<dynamic>? _sub;

  @override
  TodosState build() {
    final auth = ref.watch(authProvider);
    if (auth is! Authenticated) return const TodosInitial();

    final uid = auth.user.uid;
    final repo = ref.read(todosRepositoryProvider);

    _sub?.cancel();
    _sub = repo.watchTodos(uid: uid, listId: _listId).listen(
      (items) => state = TodosData(items),
      onError: (Object e, StackTrace st) {
        if (state is! TodosData) {
          state = TodosError(e is Failure ? e : const UnknownFailure());
        }
        // Si ya tenemos datos en pantalla, descartamos el error transitorio
        // (siguiente poll lo arreglará). Evita parpadeo de error tras resume.
      },
    );
    ref.onDispose(() => _sub?.cancel());

    return const TodosLoading();
  }

  String get _uid => (ref.read(authProvider) as Authenticated).user.uid;

  Future<void> create({required String title, String? description}) async {
    final res = await ref.read(todosRepositoryProvider).createTodo(
          uid: _uid,
          listId: _listId,
          title: title,
          description: description,
        );
    res.fold(onOk: (_) {}, onErr: (f) => state = TodosError(f));
  }

  Future<void> toggleDone(String id, bool isDone) async {
    await ref.read(todosRepositoryProvider).updateTodo(
          uid: _uid,
          listId: _listId,
          id: id,
          isDone: isDone,
        );
  }

  Future<void> updateFields({
    required String id,
    String? title,
    String? description,
    bool clearDescription = false,
  }) async {
    await ref.read(todosRepositoryProvider).updateTodo(
          uid: _uid,
          listId: _listId,
          id: id,
          title: title,
          description: description,
          clearDescription: clearDescription,
        );
  }

  Future<void> delete(String id) async {
    final todo = _findById(id);
    if (todo != null) {
      await ref.read(trashRepositoryProvider).save(
            uid: _uid,
            items: [
              TrashItem(
                kind: TrashKind.todo,
                itemId: todo.id,
                parentId: _listId,
                label: todo.title,
                payload: todo.toJson(),
              ),
            ],
          );
    }

    await ref.read(todosRepositoryProvider).deleteTodo(
          uid: _uid,
          listId: _listId,
          id: id,
        );
  }

  /// Devuelve el último todo borrado de esta lista. Devuelve si se pudo.
  Future<bool> undoLastDelete() async {
    final trash = ref.read(trashRepositoryProvider);
    final found = await trash.latestGroup(
      uid: _uid,
      kind: TrashKind.todo,
      parentId: _listId,
    );
    final entries = found.fold(
      onOk: (entries) => entries,
      onErr: (_) => const <TrashEntry>[],
    );
    // El grupo puede traer la lista delante si se borró con sus tareas: aquí
    // solo vuelven las tareas, que la lista se queda en la papelera.
    final todos = entries
        .where((entry) => entry.kind == TrashKind.todo)
        .toList(growable: false);
    if (todos.isEmpty) return false;

    final repo = ref.read(todosRepositoryProvider);
    for (final entry in todos) {
      final res = await repo.restoreTodo(
        uid: _uid,
        listId: entry.parentId ?? _listId,
        todo: Todo.fromJson(entry.payload),
      );
      if (res.isErr) return false;
    }

    await trash.remove(
      uid: _uid,
      ids: todos.map((entry) => entry.id).toList(growable: false),
    );
    return true;
  }

  Todo? _findById(String id) {
    final current = state;
    if (current is! TodosData) return null;
    for (final todo in current.items) {
      if (todo.id == id) return todo;
    }
    return null;
  }
}

final todosProvider =
    NotifierProvider.family<TodosNotifier, TodosState, String>(
  TodosNotifier.new,
);

