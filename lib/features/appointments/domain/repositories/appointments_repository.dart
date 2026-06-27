import '../../../../shared/core/result/result.dart';
import '../entities/appointment.dart';

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
    DateTime? dateTime,
    bool? isDone,
  });

  Future<Result<void>> deleteAppointment({
    required String uid,
    required String id,
  });

  /// Pausa el polling de watchers activos. Llamado al pasar la app a
  /// background para ahorrar batería y evitar errores de socket.
  void pauseAll();

  /// Reactiva el polling (con fetch inmediato) en todos los watchers
  /// previamente pausados. Llamado al volver la app a foreground.
  void resumeAll();
}
