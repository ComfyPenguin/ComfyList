import 'package:dio/dio.dart';

import '../../../../shared/core/env/firebase_endpoints.dart';
import '../../domain/entities/appointment.dart';
import '../models/appointment_dto.dart';

/// Datasource Firestore REST para `users/{uid}/appointments`.
///
/// Usa el cliente principal del [DioClient] (con [AuthInterceptor]).
class FirestoreAppointmentsRemote {
  FirestoreAppointmentsRemote(this._dio);

  final Dio _dio;

  String _collectionPath(String uid) =>
      '${FirebaseEndpoints.firestoreBase}/users/$uid/appointments';

  Future<List<Appointment>> listAppointments({
    required String uid,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      _collectionPath(uid),
    );
    final docs = (res.data?['documents'] as List?) ?? const [];
    return docs
        .cast<Map<String, dynamic>>()
        .map(AppointmentDto.fromDocument)
        .toList(growable: false);
  }

  Future<Appointment> createAppointment({
    required String uid,
    required String title,
    String? description,
    String? location,
    required DateTime dateTime,
  }) async {
    final now = DateTime.now().toUtc();
    final body = AppointmentDto.toCreateBody(
      title: title,
      description: description,
      location: location,
      dateTime: dateTime,
      now: now,
    );
    final res = await _dio.post<Map<String, dynamic>>(
      _collectionPath(uid),
      data: body,
    );
    return AppointmentDto.fromDocument(res.data!);
  }

  Future<Appointment> updateAppointment({
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
    final now = DateTime.now().toUtc();
    final (body, mask) = AppointmentDto.toPatchBody(
      title: title,
      description: description,
      clearDescription: clearDescription,
      location: location,
      clearLocation: clearLocation,
      dateTime: dateTime,
      isDone: isDone,
      now: now,
    );

    final res = await _dio.patch<Map<String, dynamic>>(
      '${_collectionPath(uid)}/$id',
      data: body,
      queryParameters: {
        if (mask.isNotEmpty) 'updateMask.fieldPaths': mask,
      },
    );
    return AppointmentDto.fromDocument(res.data!);
  }

  Future<void> deleteAppointment({
    required String uid,
    required String id,
  }) async {
    await _dio.delete<void>('${_collectionPath(uid)}/$id');
  }
}
