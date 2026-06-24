import 'dart:async';

import 'package:dio/dio.dart';

import '../../../../shared/core/failures/failure.dart';
import '../../../../shared/core/result/result.dart';
import '../../domain/entities/todo.dart';
import '../../domain/repositories/todos_repository.dart';
import '../datasources/firestore_rest_remote.dart';

/// Implementación REST con polling 15s + refresh inmediato tras mutación.
///
/// `watchTodos` devuelve un Stream construido sobre un controller broadcast:
/// emite la primera lista tras un fetch inicial, refresca por timer, y se
/// fuerza una emisión cada vez que cambia algo (create/update/delete).
///
/// Cada (uid, listId) tiene su propio watcher independiente.
class TodosRepositoryImpl implements TodosRepository {
  TodosRepositoryImpl(this._remote);

  final FirestoreRestRemote _remote;

  static const Duration _pollInterval = Duration(seconds: 15);

  // Un watcher por par (uid, listId). Permite tener varias listas abiertas
  // (p. ej. tras navegación rápida) sin que se pisen entre sí.
  final Map<_WatcherKey, _Watcher> _watchers = {};

  @override
  Stream<List<Todo>> watchTodos({
    required String uid,
    required String listId,
  }) {
    final key = _WatcherKey(uid, listId);
    final w = _watchers.putIfAbsent(
      key,
      () => _Watcher(uid, listId, _remote, _pollInterval),
    );
    return w.stream;
  }

  Future<void> _refresh(String uid, String listId) async {
    final w = _watchers[_WatcherKey(uid, listId)];
    if (w != null) await w.refreshNow();
  }

  @override
  Future<Result<List<Todo>>> fetchTodos({
    required String uid,
    required String listId,
  }) async {
    try {
      final list = await _remote.listTodos(uid: uid, listId: listId);
      return Ok(list);
    } on DioException catch (e) {
      return Err(_mapDioError(e));
    }
  }

  @override
  Future<Result<Todo>> createTodo({
    required String uid,
    required String listId,
    required String title,
    String? description,
  }) async {
    try {
      final todo = await _remote.createTodo(
        uid: uid,
        listId: listId,
        title: title,
        description: description,
      );
      await _refresh(uid, listId);
      return Ok(todo);
    } on DioException catch (e) {
      return Err(_mapDioError(e));
    }
  }

  @override
  Future<Result<Todo>> updateTodo({
    required String uid,
    required String listId,
    required String id,
    String? title,
    String? description,
    bool clearDescription = false,
    bool? isDone,
  }) async {
    try {
      final todo = await _remote.updateTodo(
        uid: uid,
        listId: listId,
        id: id,
        title: title,
        description: description,
        clearDescription: clearDescription,
        isDone: isDone,
      );
      await _refresh(uid, listId);
      return Ok(todo);
    } on DioException catch (e) {
      return Err(_mapDioError(e));
    }
  }

  @override
  Future<Result<void>> deleteTodo({
    required String uid,
    required String listId,
    required String id,
  }) async {
    try {
      await _remote.deleteTodo(uid: uid, listId: listId, id: id);
      await _refresh(uid, listId);
      return const Ok(null);
    } on DioException catch (e) {
      return Err(_mapDioError(e));
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

class _WatcherKey {
  const _WatcherKey(this.uid, this.listId);
  final String uid;
  final String listId;

  @override
  bool operator ==(Object other) =>
      other is _WatcherKey && other.uid == uid && other.listId == listId;

  @override
  int get hashCode => Object.hash(uid, listId);
}

class _Watcher {
  _Watcher(this.uid, this.listId, this._remote, this._interval) {
    _controller = StreamController<List<Todo>>.broadcast(
      onListen: _start,
      onCancel: _stop,
    );
  }

  final String uid;
  final String listId;
  final FirestoreRestRemote _remote;
  final Duration _interval;

  late final StreamController<List<Todo>> _controller;
  Timer? _timer;
  bool _running = false;

  Stream<List<Todo>> get stream => _controller.stream;

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

  Future<void> refreshNow() async {
    try {
      final list = await _remote.listTodos(uid: uid, listId: listId);
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
