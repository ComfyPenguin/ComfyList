import 'dart:async';

import 'package:dio/dio.dart';

import '../../../../shared/core/failures/failure.dart';
import '../../../../shared/core/logging/debug_log.dart';
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

  _Watcher? _watcher;
  String? _watcherUid;
  DateTime? _lastDeletedAt;

  /// Los guardados van encadenados: cada uno recorta leyendo toda la colección,
  /// y dos a la vez deciden sobre la misma foto y dejan la cuenta por encima
  /// del tope.
  Future<void> _writes = Future.value();

  @override
  Future<Result<void>> save({
    required String uid,
    required List<TrashItem> items,
  }) {
    if (items.isEmpty) return Future.value(const Ok(null));

    final done = _writes.then((_) => _saveNow(uid: uid, items: items));
    // La cola sigue aunque un guardado reviente: el siguiente no hereda su
    // error.
    _writes = done.then((_) {}, onError: (_) {});
    return done;
  }

  Future<Result<void>> _saveNow({
    required String uid,
    required List<TrashItem> items,
  }) async {
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
      final entries = await _remote.listEntries(uid);
      await _trim(_remote, uid, entries);
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
  Future<Result<void>> purgeExpired({
    required String uid,
    required int days,
  }) async {
    if (days <= 0) return const Ok(null);
    try {
      final cutoff = DateTime.now().toUtc().subtract(Duration(days: days));
      var removed = false;
      for (final entry in await _remote.listEntries(uid)) {
        if (entry.deletedAt.isBefore(cutoff)) {
          await _remote.deleteEntry(uid: uid, id: entry.id);
          removed = true;
        }
      }
      if (removed) await _refresh(uid);
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
      // Leer también recorta: si la cuenta se quedó por encima del tope (un
      // recorte que falló, dos borrados que se pisaron), entrar en la papelera
      // lo arregla sin esperar al siguiente borrado.
      final entries = await _remote.listEntries(uid);
      final shown = await _trim(_remote, uid, entries);
      if (!_controller.isClosed) _controller.add(shown);
    } catch (e, st) {
      if (!_controller.isClosed) _controller.addError(e, st);
    }
  }

  void dispose() {
    _timer?.cancel();
    _controller.close();
  }
}

/// Recorta la papelera a los [TrashRepository.maxGroupsPerUid] borrados más
/// recientes y devuelve lo que queda, ya lo último borrado primero. Cuenta
/// borrados y no elementos, así que un borrado entra o se va entero: una lista
/// sin sus tareas no se puede restaurar. Se llama al guardar y al leer, que del
/// tope responde la cuenta y no el último recorte.
///
/// Best-effort: lo que no se pueda tirar se queda y se reintenta en la pasada
/// siguiente, que la papelera se enseña igual.
Future<List<TrashEntry>> _trim(
  FirestoreTrashRemote remote,
  String uid,
  List<TrashEntry> entries,
) async {
  final sorted = _newestFirst(entries);

  final ids = <String>[];
  final seen = <String>{};
  for (final entry in sorted) {
    if (seen.add(entry.groupId)) ids.add(entry.groupId);
  }
  if (ids.length <= TrashRepository.maxGroupsPerUid) return sorted;

  final dropped = ids.skip(TrashRepository.maxGroupsPerUid).toSet();
  final shown = <TrashEntry>[];
  for (final entry in sorted) {
    if (!dropped.contains(entry.groupId)) {
      shown.add(entry);
      continue;
    }
    try {
      await remote.deleteEntry(uid: uid, id: entry.id);
    } on DioException catch (e) {
      debugLog('El recorte de la papelera falló: ${e.type}');
      shown.add(entry);
    }
  }
  return shown;
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
