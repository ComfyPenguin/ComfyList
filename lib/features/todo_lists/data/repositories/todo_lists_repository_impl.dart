import 'dart:async';

import 'package:dio/dio.dart';

import '../../../../shared/core/failures/failure.dart';
import '../../../../shared/core/result/result.dart';
import '../../domain/entities/todo_list.dart';
import '../../domain/repositories/todo_lists_repository.dart';
import '../datasources/firestore_lists_remote.dart';

/// Implementación REST con polling 15s + refresh inmediato tras mutación.
/// Mismo patrón que TodosRepositoryImpl.
class TodoListsRepositoryImpl implements TodoListsRepository {
  TodoListsRepositoryImpl(this._remote);

  final FirestoreListsRemote _remote;

  static const Duration _pollInterval = Duration(seconds: 15);

  final Map<String, _Watcher> _watchers = {};

  @override
  Stream<List<TodoList>> watchLists(String uid) {
    final w = _watchers.putIfAbsent(
      uid,
      () => _Watcher(uid, _remote, _pollInterval),
    );
    return w.stream;
  }

  Future<void> _refresh(String uid) async {
    final w = _watchers[uid];
    if (w != null) await w.refreshNow();
  }

  @override
  Future<Result<List<TodoList>>> fetchLists(String uid) async {
    try {
      final list = await _remote.listLists(uid);
      return Ok(list);
    } on DioException catch (e) {
      return Err(_mapDioError(e));
    }
  }

  @override
  Future<Result<TodoList>> createList({
    required String uid,
    required String name,
    required String iconKey,
  }) async {
    try {
      final created = await _remote.createList(
        uid: uid,
        name: name,
        iconKey: iconKey,
      );
      await _refresh(uid);
      return Ok(created);
    } on DioException catch (e) {
      return Err(_mapDioError(e));
    }
  }

  @override
  Future<Result<TodoList>> updateList({
    required String uid,
    required String id,
    String? name,
    String? iconKey,
  }) async {
    try {
      final updated = await _remote.updateList(
        uid: uid,
        id: id,
        name: name,
        iconKey: iconKey,
      );
      await _refresh(uid);
      return Ok(updated);
    } on DioException catch (e) {
      return Err(_mapDioError(e));
    }
  }

  @override
  Future<Result<void>> deleteList({
    required String uid,
    required String id,
  }) async {
    try {
      // Cascade manual: Firestore no borra subcolecciones automáticamente,
      // así que recogemos los IDs de todos y los borramos antes de la lista.
      // Si esto falla a la mitad, la lista quedaría inconsistente — para v1
      // asumimos que el coste/riesgo es aceptable (mejor que dejar
      // huérfanos siempre).
      final todoIds = await _remote.listTodoIdsOfList(uid: uid, listId: id);
      for (final todoId in todoIds) {
        await _remote.deleteTodoOfList(
          uid: uid,
          listId: id,
          todoId: todoId,
        );
      }
      await _remote.deleteList(uid: uid, id: id);
      await _refresh(uid);
      return const Ok(null);
    } on DioException catch (e) {
      return Err(_mapDioError(e));
    }
  }

  @override
  void pauseAll() {
    for (final w in _watchers.values) {
      w.pause();
    }
  }

  @override
  void resumeAll() {
    for (final w in _watchers.values) {
      w.resume();
    }
  }

  void dispose() {
    for (final w in _watchers.values) {
      w.dispose();
    }
    _watchers.clear();
  }

  Failure _mapDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return const TimeoutFailure();
    }
    if (e.type == DioExceptionType.connectionError) {
      return const NetworkFailure();
    }
    if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
      return const AuthFailure();
    }
    if (e.response?.statusCode == 404) {
      return const NotFoundFailure();
    }
    return ServerFailure('Error ${e.response?.statusCode ?? "?"}');
  }
}

class _Watcher {
  _Watcher(this.uid, this._remote, this._interval) {
    _controller = StreamController<List<TodoList>>.broadcast(
      onListen: _start,
      onCancel: _stop,
    );
  }

  final String uid;
  final FirestoreListsRemote _remote;
  final Duration _interval;

  late final StreamController<List<TodoList>> _controller;
  Timer? _timer;
  bool _running = false;

  Stream<List<TodoList>> get stream => _controller.stream;

  void _start() {
    if (_running) return;
    _running = true;
    refreshNow();
    _timer = Timer.periodic(_interval, (_) => refreshNow());
  }

  void _stop() {
    if (_controller.hasListener) return;
    _timer?.cancel();
    _timer = null;
    _running = false;
  }

  // Pausa el polling en background: el OS mata los sockets y el primer tick
  // tras resume lanzaría errores de red/auth contra token/conexión caducados.
  void pause() {
    _timer?.cancel();
    _timer = null;
  }

  // Reanuda el polling al volver a foreground; refreshNow fuerza un fetch
  // inmediato para no esperar al siguiente tick del Timer.periodic.
  void resume() {
    if (_running && _timer == null && _controller.hasListener) {
      refreshNow();
      _timer = Timer.periodic(_interval, (_) => refreshNow());
    }
  }

  Future<void> refreshNow() async {
    try {
      final list = await _remote.listLists(uid);
      if (!_controller.isClosed) _controller.add(list);
    } catch (e, st) {
      if (!_controller.isClosed) _controller.addError(e, st);
    }
  }

  void dispose() {
    _timer?.cancel();
    _controller.close();
  }
}
