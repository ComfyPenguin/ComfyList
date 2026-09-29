import 'dart:async';

import 'package:dio/dio.dart';

import '../../../../shared/core/failures/failure.dart';
import '../../../../shared/core/result/result.dart';
import '../../../../shared/core/time/clock.dart';
import '../../domain/entities/trash_entry.dart';
import '../../domain/repositories/trash_repository.dart';
import '../datasources/firestore_trash_remote.dart';

/// Papelera en Firestore (`users/{uid}/trash`), con polling como el resto de
/// features: el stream emite la lista tras un fetch inicial, refresca por timer
/// y se fuerza una emisión tras cada mutación.
class TrashRepositoryImpl implements TrashRepository {
  TrashRepositoryImpl(this._remote, {this.pollInterval = defaultPollInterval});

  final FirestoreTrashRemote _remote;

  /// Cada cuánto vuelve a pedir la papelera el watcher activo. En la app lo fija
  /// [pollIntervalProvider]; los tests lo acortan para no esperar al tick real.
  final Duration pollInterval;

  /// Cuántos borrados se guardan por cuenta: más allá de esto solo hace bulto.
  static const int maxEntriesPerUid = 100;

  _Watcher? _watcher;
  String? _watcherUid;
  DateTime? _lastDeletedAt;

  @override
  Future<Result<void>> save({
    required String uid,
    required List<TrashItem> items,
  }) async {
    if (items.isEmpty) return const Ok(null);
    try {
      final deletedAt = _nextDeletedAt();
      final groupId = deletedAt.microsecondsSinceEpoch.toString();
      for (final item in items) {
        await _remote.createEntry(
          uid: uid,
          groupId: groupId,
          item: item,
          deletedAt: deletedAt,
        );
      }
      await _trim(uid);
      await _refresh(uid);
      return const Ok(null);
    } on DioException catch (e) {
      return Err(_mapDioError(e));
    }
  }

  @override
  Future<Result<List<TrashEntry>>> latestGroup({
    required String uid,
    required TrashKind kind,
    String? parentId,
  }) async {
    try {
      final entries = _newestFirst(await _remote.listEntries(uid));
      final newest = _newestMatching(entries, kind: kind, parentId: parentId);
      if (newest == null) return const Ok([]);
      return Ok(
        entries
            .where((entry) => entry.groupId == newest.groupId)
            .toList(growable: false),
      );
    } on DioException catch (e) {
      return Err(_mapDioError(e));
    }
  }

  @override
  Future<Result<List<TrashEntry>>> list(String uid) async {
    try {
      return Ok(_newestFirst(await _remote.listEntries(uid)));
    } on DioException catch (e) {
      return Err(_mapDioError(e));
    }
  }

  @override
  Stream<List<TrashEntry>> watch(String uid) {
    if (_watcher == null || _watcherUid != uid) {
      _watcher?.dispose();
      _watcher = _Watcher(uid, _remote, pollInterval);
      _watcherUid = uid;
    }
    return _watcher!.stream;
  }

  @override
  Future<Result<void>> remove({
    required String uid,
    required List<String> ids,
  }) async {
    if (ids.isEmpty) return const Ok(null);
    try {
      for (final id in ids) {
        await _remote.deleteEntry(uid: uid, id: id);
      }
      await _refresh(uid);
      return const Ok(null);
    } on DioException catch (e) {
      return Err(_mapDioError(e));
    }
  }

  @override
  Future<Result<void>> empty(String uid) async {
    try {
      final entries = await _remote.listEntries(uid);
      for (final entry in entries) {
        await _remote.deleteEntry(uid: uid, id: entry.id);
      }
      await _refresh(uid);
      return const Ok(null);
    } on DioException catch (e) {
      return Err(_mapDioError(e));
    }
  }

  @override
  void pauseAll() => _watcher?.pause();

  @override
  void resumeAll() => _watcher?.resume();

  void dispose() {
    _watcher?.dispose();
    _watcher = null;
    _watcherUid = null;
  }

  /// Deja solo los [maxEntriesPerUid] borrados más recientes de la cuenta.
  Future<void> _trim(String uid) async {
    final entries = _newestFirst(await _remote.listEntries(uid));
    for (final entry in entries.skip(maxEntriesPerUid)) {
      await _remote.deleteEntry(uid: uid, id: entry.id);
    }
  }

  Future<void> _refresh(String uid) async {
    if (_watcherUid != uid) return;
    await _watcher?.refreshNow();
  }

  TrashEntry? _newestMatching(
    List<TrashEntry> entries, {
    required TrashKind kind,
    String? parentId,
  }) {
    for (final entry in entries) {
      if (entry.kind == kind &&
          (parentId == null || entry.parentId == parentId)) {
        return entry;
      }
    }
    return null;
  }

  /// Marca temporal del borrado, siempre mayor que la del anterior. El reloj
  /// del sistema no llega al microsegundo, así que dos borrados seguidos
  /// podrían empatar: eso los juntaría en un mismo grupo (y en un mismo
  /// «deshacer») y dejaría el orden al azar.
  DateTime _nextDeletedAt() {
    final now = DateTime.now().toUtc();
    final last = _lastDeletedAt;
    final next = (last == null || now.isAfter(last))
        ? now
        : last.add(const Duration(microseconds: 1));
    _lastDeletedAt = next;
    return next;
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
    _controller = StreamController<List<TrashEntry>>.broadcast(
      onListen: _start,
      onCancel: _stop,
    );
  }

  final String uid;
  final FirestoreTrashRemote _remote;
  final Duration _interval;

  late final StreamController<List<TrashEntry>> _controller;
  Timer? _timer;
  bool _running = false;

  Stream<List<TrashEntry>> get stream => _controller.stream;

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

  void resume() {
    if (_running && _timer == null && _controller.hasListener) {
      refreshNow();
      _timer = Timer.periodic(_interval, (_) => refreshNow());
    }
  }

  Future<void> refreshNow() async {
    try {
      final entries = await _remote.listEntries(uid);
      if (!_controller.isClosed) _controller.add(_newestFirst(entries));
    } catch (e, st) {
      if (!_controller.isClosed) _controller.addError(e, st);
    }
  }

  void dispose() {
    _timer?.cancel();
    _controller.close();
  }
}

/// Lo último borrado primero; el id desempata (los elementos de un mismo
/// borrado comparten instante).
List<TrashEntry> _newestFirst(List<TrashEntry> entries) {
  final sorted = [...entries];
  sorted.sort((a, b) {
    final byDate = b.deletedAt.compareTo(a.deletedAt);
    return byDate != 0 ? byDate : b.id.compareTo(a.id);
  });
  return sorted;
}
