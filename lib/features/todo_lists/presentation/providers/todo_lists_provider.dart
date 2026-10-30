import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/core/failures/failure.dart';
import '../../../../shared/core/lifecycle/polling_registry.dart';
import '../../../../shared/core/time/clock.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/providers/auth_state.dart';
import '../../../trash/domain/entities/trash_group.dart';
import '../../../trash/presentation/providers/deletions_provider.dart';
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
    registry: ref.watch(pollingRegistryProvider),
  );
  ref.onDispose(repo.dispose);
  return repo;
});

/// Notifier de listas de tareas. Re-construye al cambiar [authProvider].
class TodoListsNotifier extends Notifier<TodoListsState> {
  StreamSubscription<dynamic>? _sub;

  /// Listas que se están borrando: se ocultan al instante sin esperar a que el
  /// servidor deje de devolverlas.
  final Set<String> _hidden = {};

  /// Lo último que llegó del stream, sin filtrar.
  List<TodoList> _lastItems = const [];

  @override
  TodoListsState build() {
    final auth = ref.watch(authProvider);
    if (auth is! Authenticated) return const TodoListsInitial();

    final uid = auth.user.uid;
    final repo = ref.read(todoListsRepositoryProvider);

    _hidden.clear();
    _lastItems = const [];
    _sub?.cancel();
    _sub = repo.watchLists(uid).listen(
      (items) {
        _lastItems = items;
        // Lo que el servidor ya no devuelve deja de hacer falta ocultarlo.
        _hidden.removeWhere((id) => !items.any((list) => list.id == id));
        state = TodoListsData(_visible());
      },
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

  List<TodoList> _visible() => [
        for (final list in _lastItems)
          if (!_hidden.contains(list.id)) list,
      ];

  void _unhide(String id) {
    _hidden.remove(id);
    if (state is TodoListsData) state = TodoListsData(_visible());
  }

  /// Borra [id] con sus tareas y con copia en la papelera. Devuelve el borrado,
  /// que es lo que hay que pasar a [undo], o `null` si no se pudo: sin leer las
  /// tareas ni guardar la copia no se borra nada. La lista desaparece de la
  /// pantalla de inmediato y vuelve si el borrado falla.
  Future<TrashGroup?> delete(String id) async {
    final list = _findById(id);
    if (list == null) return null;

    _hidden.add(id);
    if (state is TodoListsData) state = TodoListsData(_visible());

    final res = await ref.read(deletionsProvider).deleteList(
          uid: _uid,
          list: list,
        );
    return res.fold(
      onOk: (group) => group,
      onErr: (_) {
        _unhide(id);
        return null;
      },
    );
  }

  /// Devuelve [group], el borrado que acaba de hacer [delete], con sus tareas.
  /// Devuelve si se pudo.
  Future<bool> undo(TrashGroup group) async {
    if (!await ref.read(deletionsProvider).restore(group)) return false;

    // Si el refresco tras borrarla falló, la lista seguiría oculta.
    _unhide(group.header.itemId);
    return true;
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
