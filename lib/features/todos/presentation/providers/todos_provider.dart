import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/core/failures/failure.dart';
import '../../../../shared/core/lifecycle/polling_registry.dart';
import '../../../../shared/core/time/clock.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/providers/auth_state.dart';
import '../../../trash/domain/entities/trash_group.dart';
import '../../../trash/presentation/providers/deletions_provider.dart';
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

  /// Borra la tarea con copia en la papelera. Devuelve el borrado, que es lo
  /// que hay que pasar a [undo], o `null` si no se pudo: sin copia no se borra.
  Future<TrashGroup?> delete(String id) async {
    final todo = _findById(id);
    if (todo == null) return null;

    final res = await ref.read(deletionsProvider).deleteTodo(
          uid: _uid,
          listId: _listId,
          todo: todo,
        );
    return res.fold(onOk: (group) => group, onErr: (_) => null);
  }

  /// Devuelve [group], el borrado que acaba de hacer [delete]. Devuelve si se
  /// pudo.
  Future<bool> undo(TrashGroup group) =>
      ref.read(deletionsProvider).restore(group);

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

