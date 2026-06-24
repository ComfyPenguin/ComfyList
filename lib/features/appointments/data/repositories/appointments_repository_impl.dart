import 'dart:async';

import 'package:dio/dio.dart';

import '../../../../shared/core/failures/failure.dart';
import '../../../../shared/core/result/result.dart';
import '../../domain/entities/appointment.dart';
import '../../domain/repositories/appointments_repository.dart';
import '../datasources/firestore_appointments_remote.dart';

/// Implementación REST con polling 15s + refresh inmediato tras mutación.
///
/// `watchAppointments` devuelve un Stream construido sobre un controller broadcast:
/// emite la primera lista tras un fetch inicial, refresca por timer, y se
/// fuerza una emisión cada vez que cambia algo (create/update/delete).
///
/// Cada uid tiene su propio watcher independiente.
class AppointmentsRepositoryImpl implements AppointmentsRepository {
  AppointmentsRepositoryImpl(this._remote);

  final FirestoreAppointmentsRemote _remote;

  static const Duration _pollInterval = Duration(seconds: 15);

  // Un watcher por uid. Permite tener varias sesiones abiertas
  // (p. ej. tras navegación rápida) sin que se pisen entre sí.
  final Map<String, _Watcher> _watchers = {};

  @override
  Stream<List<Appointment>> watchAppointments(String uid) {
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
  Future<Result<List<Appointment>>> fetchAppointments(String uid) async {
    try {
      final list = await _remote.listAppointments(uid: uid);
      return Ok(list);
    } on DioException catch (e) {
      return Err(_mapDioError(e));
    }
  }

  @override
  Future<Result<Appointment>> createAppointment({
    required String uid,
    required String title,
    String? description,
    String? location,
    required DateTime dateTime,
  }) async {
    try {
      final appointment = await _remote.createAppointment(
        uid: uid,
        title: title,
        description: description,
        location: location,
        dateTime: dateTime,
      );
      await _refresh(uid);
      return Ok(appointment);
    } on DioException catch (e) {
      return Err(_mapDioError(e));
    }
  }

  @override
  Future<Result<Appointment>> updateAppointment({
    required String uid,
    required String id,
    String? title,
    String? description,
    bool clearDescription = false,
    String? location,
    bool clearLocation = false,
    DateTime? dateTime,
    bool? isDone,
  }) async {
    try {
      final appointment = await _remote.updateAppointment(
        uid: uid,
        id: id,
        title: title,
        description: description,
        clearDescription: clearDescription,
        location: location,
        clearLocation: clearLocation,
        dateTime: dateTime,
        isDone: isDone,
      );
      await _refresh(uid);
      return Ok(appointment);
    } on DioException catch (e) {
      return Err(_mapDioError(e));
    }
  }

  @override
  Future<Result<void>> deleteAppointment({
    required String uid,
    required String id,
  }) async {
    try {
      await _remote.deleteAppointment(uid: uid, id: id);
      await _refresh(uid);
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

class _Watcher {
  _Watcher(this.uid, this._remote, this._interval) {
    _controller = StreamController<List<Appointment>>.broadcast(
      onListen: _start,
      onCancel: _stop,
    );
  }

  final String uid;
  final FirestoreAppointmentsRemote _remote;
  final Duration _interval;

  late final StreamController<List<Appointment>> _controller;
  Timer? _timer;
  bool _running = false;

  Stream<List<Appointment>> get stream => _controller.stream;

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
      final list = await _remote.listAppointments(uid: uid);
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
