import '../../../../shared/core/result/result.dart';
import '../entities/appointment.dart';
import '../entities/repeat_rule.dart';

abstract class AppointmentsRepository {
  /// Stream que emite la lista actual de citas de un [uid] concreto.
  /// La implementación REST hace polling cada 15s + emite tras cada mutación.
  Stream<List<Appointment>> watchAppointments(String uid);

  Future<Result<List<Appointment>>> fetchAppointments(String uid);

  Future<Result<Appointment>> createAppointment({
    required String uid,
    required String title,
    String? description,
    String? location,
    RepeatRule? repeatRule,
    required DateTime dateTime,
  });

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
  });

  Future<Result<void>> deleteAppointment({
    required String uid,
    required String id,
  });

  /// Devuelve [appointment] a Firestore con su mismo id, para deshacer el
  /// borrado.
  Future<Result<Appointment>> restoreAppointment({
    required String uid,
    required Appointment appointment,
  });
}
