import 'dart:async';

import 'package:dio/dio.dart';

import '../../core/failures/failure.dart';
import '../../core/lifecycle/polling_registry.dart';
import '../../core/result/result.dart';

/// Traduce un error de red de Dio al [Failure] que entiende la app.
Failure mapDioFailure(DioException e) {
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

/// Colección sondeada: mantiene al día una lista de elementos por clave [K].
///
/// [watch] emite la primera lista tras un fetch inmediato y la refresca cada
/// [interval] mientras haya oyentes. Cada clave tiene su propio watcher, así que
/// varias claves (p. ej. varias listas abiertas) no se pisan. Las mutaciones
/// pasan por [guard], que fuerza una emisión al terminar.
///
/// Los watchers se apuntan en el [PollingRegistry] para que la app los pause
/// en segundo plano.
class PolledCollection<K, T> {
  PolledCollection({
    required Future<List<T>> Function(K key) fetch,
    required Duration interval,
    PollingRegistry? registry,
  })  : _fetch = fetch,
        _interval = interval,
        _registry = registry ?? PollingRegistry();

  final Future<List<T>> Function(K key) _fetch;
  final Duration _interval;
  final PollingRegistry _registry;

  final Map<K, _Watcher<T>> _watchers = {};

  Stream<List<T>> watch(K key) {
    final watcher = _watchers.putIfAbsent(key, () {
      final created = _Watcher<T>(() => _fetch(key), _interval);
      _registry.register(created);
      return created;
    });
    return watcher.stream;
  }

  /// Vuelve a pedir ahora la lista de [key], si alguien la está mirando.
  Future<void> refresh(K key) async {
    final watcher = _watchers[key];
    if (watcher != null) await watcher.refreshNow();
  }

  /// Ejecuta una mutación, espera al refresco de [key] y devuelve su resultado.
  /// El refresco no convierte un `Ok` en `Err`: si falla, el error va al
  /// stream.
  Future<Result<R>> guard<R>(K key, Future<R> Function() mutate) async {
    try {
      final value = await mutate();
      await refresh(key);
      return Ok(value);
    } on DioException catch (e) {
      return Err(mapDioFailure(e));
    }
  }

  /// Como [guard] pero sin refrescar: para lecturas puntuales.
  Future<Result<R>> read<R>(Future<R> Function() action) async {
    try {
      return Ok(await action());
    } on DioException catch (e) {
      return Err(mapDioFailure(e));
    }
  }

  void dispose() {
    for (final watcher in _watchers.values) {
      _registry.unregister(watcher);
      watcher.dispose();
    }
    _watchers.clear();
  }
}

class _Watcher<T> implements PollingMember {
  _Watcher(this._fetch, this._interval) {
    _controller = StreamController<List<T>>.broadcast(
      onListen: _start,
      onCancel: _stop,
    );
  }

  final Future<List<T>> Function() _fetch;
  final Duration _interval;

  late final StreamController<List<T>> _controller;
  Timer? _timer;
  bool _running = false;

  Stream<List<T>> get stream => _controller.stream;

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
  @override
  void pause() {
    _timer?.cancel();
    _timer = null;
  }

  // Reanuda el polling al volver a foreground; refreshNow fuerza un fetch
  // inmediato para no esperar al siguiente tick del Timer.periodic.
  @override
  void resume() {
    if (_running && _timer == null && _controller.hasListener) {
      refreshNow();
      _timer = Timer.periodic(_interval, (_) => refreshNow());
    }
  }

  Future<void> refreshNow() async {
    try {
      final list = await _fetch();
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
