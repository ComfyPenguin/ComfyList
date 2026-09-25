import 'package:comfy_list/features/appointments/data/models/appointment_dto.dart';
import 'package:comfy_list/features/appointments/domain/entities/appointment.dart';
import 'package:comfy_list/shared/data/remote/firestore_value_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppointmentDto', () {
    test('fromDocument decodes description, location, and dateTime', () {
      final raw = <String, dynamic>{
        'name': 'projects/p/databases/(default)/documents/users/u1/appointments/a1',
        'fields': FirestoreValueCodec.encodeFields(<String, dynamic>{
          'title': 'Dentista',
          'description': 'Limpieza',
          'location': 'Calle Mayor 1',
          'dateTime': DateTime.utc(2026, 6, 1, 9),
          'isDone': false,
          'createdAt': DateTime.utc(2026, 1, 1),
          'updatedAt': DateTime.utc(2026, 1, 1),
        })['fields'],
      };

      final appointment = AppointmentDto.fromDocument(raw);

      expect(appointment.id, 'a1');
      expect(appointment.title, 'Dentista');
      expect(appointment.description, 'Limpieza');
      expect(appointment.location, 'Calle Mayor 1');
      expect(appointment.dateTime.toUtc(), DateTime.utc(2026, 6, 1, 9));
      expect(appointment.isDone, isFalse);
    });

    test('fromDocument returns defaults for missing optional fields', () {
      final raw = <String, dynamic>{
        'name': 'projects/p/databases/(default)/documents/users/u1/appointments/a2',
        'fields': FirestoreValueCodec.encodeFields(<String, dynamic>{
          'title': 'Médico',
          'isDone': false,
        })['fields'],
      };

      final appointment = AppointmentDto.fromDocument(raw);

      expect(appointment.id, 'a2');
      expect(appointment.title, 'Médico');
      expect(appointment.description, isNull);
      expect(appointment.location, isNull);
    });

    test('toPatchBody with clearLocation emits null with the field in the mask',
        () {
      final t = DateTime.utc(2026, 6, 1, 9);
      final (body, mask) = AppointmentDto.toPatchBody(
        clearLocation: true,
        now: t,
      );

      expect(mask, contains('location'));
      expect(mask, contains('updatedAt'));

      final encodedFields = body['fields'] as Map<String, dynamic>;
      expect(encodedFields['location'], <String, dynamic>{
        'nullValue': null,
      });
    });

    test('toRestoreBody devuelve la cita con su ubicación y su estado', () {
      final appointment = Appointment(
        id: 'a1',
        title: 'Dentista',
        description: 'Limpieza',
        location: 'Calle Mayor 1',
        dateTime: DateTime.utc(2026, 6, 1, 9),
        isDone: true,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 2),
      );

      final decoded = FirestoreValueCodec.decodeFields(
        AppointmentDto.toRestoreBody(appointment),
      );

      expect(decoded['title'], 'Dentista');
      expect(decoded['description'], 'Limpieza');
      expect(decoded['location'], 'Calle Mayor 1');
      expect(decoded['isDone'], isTrue);
      expect(
        (decoded['dateTime'] as DateTime).toUtc(),
        DateTime.utc(2026, 6, 1, 9),
      );
      expect(
        (decoded['createdAt'] as DateTime).toUtc(),
        DateTime.utc(2026, 1, 1),
      );
    });

    test('toPatchBody with only isDone includes isDone in mask', () {
      final t = DateTime.utc(2026, 6, 1, 9);
      final (body, mask) = AppointmentDto.toPatchBody(
        isDone: true,
        now: t,
      );

      expect(mask, contains('isDone'));
      expect(mask, isNot(contains('title')));
      expect(mask, isNot(contains('description')));
      expect(mask, isNot(contains('location')));
      expect(mask, contains('updatedAt'));

      final decoded = FirestoreValueCodec.decodeFields(body);
      expect(decoded['isDone'], isTrue);
    });
  });
}
