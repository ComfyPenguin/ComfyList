import '../../../../shared/core/lifecycle/polling_registry.dart';
import '../../../../shared/core/result/result.dart';
import '../../../../shared/core/time/clock.dart';
import '../../../../shared/data/remote/polled_collection.dart';
import '../../domain/entities/appointment.dart';
import '../../domain/entities/repeat_rule.dart';
import '../../domain/repositories/appointments_repository.dart';
import '../datasources/firestore_appointments_remote.dart';

/// Implementación REST con polling 15s + refresh inmediato tras mutación,
/// que lleva la [PolledCollection] de citas de cada usuario.
class AppointmentsRepositoryImpl implements AppointmentsRepository {
  AppointmentsRepositoryImpl(
    this._remote, {
    Duration pollInterval = defaultPollInterval,
    PollingRegistry? registry,
  }) : _appointments = PolledCollection<String, Appointment>(
          fetch: (uid) => _remote.listAppointments(uid: uid),
          interval: pollInterval,
          registry: registry,
        );

  final FirestoreAppointmentsRemote _remote;

  final PolledCollection<String, Appointment> _appointments;

  @override
  Stream<List<Appointment>> watchAppointments(String uid) =>
      _appointments.watch(uid);

  @override
  Future<Result<List<Appointment>>> fetchAppointments(String uid) =>
      _appointments.read(() => _remote.listAppointments(uid: uid));

  @override
  Future<Result<Appointment>> createAppointment({
    required String uid,
    required String title,
    String? description,
    String? location,
    RepeatRule? repeatRule,
    required DateTime dateTime,
  }) =>
      _appointments.guard(
        uid,
        () => _remote.createAppointment(
          uid: uid,
          title: title,
          description: description,
          location: location,
          repeatRule: repeatRule,
          dateTime: dateTime,
        ),
      );

  @override
  Future<Result<Appointment>> updateAppointment({
    required String uid,
    required String id,
    String? title,
    String? description,
    bool clearDescription = false,
    String? location,
    bool clearLocation = false,
    RepeatRule? repeatRule,
    bool clearRepeatRule = false,
    DateTime? dateTime,
    bool? isDone,
  }) =>
      _appointments.guard(
        uid,
        () => _remote.updateAppointment(
          uid: uid,
          id: id,
          title: title,
          description: description,
          clearDescription: clearDescription,
          location: location,
          clearLocation: clearLocation,
          repeatRule: repeatRule,
          clearRepeatRule: clearRepeatRule,
          dateTime: dateTime,
          isDone: isDone,
        ),
      );

  @override
  Future<Result<void>> deleteAppointment({
    required String uid,
    required String id,
  }) =>
      _appointments.guard(
        uid,
        () => _remote.deleteAppointment(uid: uid, id: id),
      );

  @override
  Future<Result<Appointment>> restoreAppointment({
    required String uid,
    required Appointment appointment,
  }) =>
      _appointments.guard(
        uid,
        () => _remote.restoreAppointment(uid: uid, appointment: appointment),
      );

  void dispose() => _appointments.dispose();
}
