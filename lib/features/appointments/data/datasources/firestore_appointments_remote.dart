import 'package:dio/dio.dart';

import '../../../../shared/core/env/firebase_endpoints.dart';
import '../../../../shared/core/time/clock.dart';
import '../../../../shared/data/remote/firestore_documents.dart';
import '../../../../shared/data/remote/firestore_pages.dart';
import '../../domain/entities/appointment.dart';
import '../../domain/entities/repeat_rule.dart';
import '../models/appointment_dto.dart';

/// Datasource Firestore REST para `users/{uid}/appointments`.
///
/// Usa el cliente principal del [DioClient] (con [AuthInterceptor]). [now] da
/// el «ahora» de `createdAt` y `updatedAt`; en la app es el reloj de la app.
class FirestoreAppointmentsRemote {
  FirestoreAppointmentsRemote(this._dio, {Now now = DateTime.now})
      : _now = now;

  final Dio _dio;
  final Now _now;

  String _collectionPath(String uid) =>
      '${FirebaseEndpoints.firestoreBase}/users/$uid/appointments';

  Future<List<Appointment>> listAppointments({
    required String uid,
  }) async {
    final docs = await _dio.getAllDocuments(_collectionPath(uid));
    return docs
        .map(AppointmentDto.fromDocument)
        .toList(growable: false);
  }

  Future<Appointment> createAppointment({
    required String uid,
    required String title,
    String? description,
    String? location,
    RepeatRule? repeatRule,
    required List<int> reminderMinutes,
    required DateTime dateTime,
  }) async {
    final body = AppointmentDto.toCreateBody(
      title: title,
      description: description,
      location: location,
      repeatRule: repeatRule,
      reminderMinutes: reminderMinutes,
      dateTime: dateTime,
      now: _now().toUtc(),
    );
    return AppointmentDto.fromDocument(
      await _dio.createDocument(_collectionPath(uid), body),
    );
  }

  Future<Appointment> updateAppointment({
    required String uid,
    required String id,
    String? title,
    String? description,
    bool clearDescription = false,
    String? location,
    bool clearLocation = false,
    RepeatRule? repeatRule,
    bool clearRepeatRule = false,
    List<int>? reminderMinutes,
    DateTime? dateTime,
    bool? isDone,
  }) async {
    final (body, mask) = AppointmentDto.toPatchBody(
      title: title,
      description: description,
      clearDescription: clearDescription,
      location: location,
      clearLocation: clearLocation,
      repeatRule: repeatRule,
      clearRepeatRule: clearRepeatRule,
      reminderMinutes: reminderMinutes,
      dateTime: dateTime,
      isDone: isDone,
      now: _now().toUtc(),
    );
    return AppointmentDto.fromDocument(
      await _dio.patchDocument(
        '${_collectionPath(uid)}/$id',
        body,
        updateMask: mask,
      ),
    );
  }

  Future<void> deleteAppointment({
    required String uid,
    required String id,
  }) async {
    await _dio.delete<void>('${_collectionPath(uid)}/$id');
  }

  /// Vuelve a escribir el documento de [appointment] con su mismo id.
  Future<Appointment> restoreAppointment({
    required String uid,
    required Appointment appointment,
  }) async {
    return AppointmentDto.fromDocument(
      await _dio.patchDocument(
        '${_collectionPath(uid)}/${appointment.id}',
        AppointmentDto.toRestoreBody(appointment),
      ),
    );
  }
}
