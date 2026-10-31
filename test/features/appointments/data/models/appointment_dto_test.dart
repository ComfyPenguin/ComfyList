import 'package:comfy_list/features/appointments/data/models/appointment_dto.dart';
import 'package:comfy_list/features/appointments/domain/entities/appointment.dart';
import 'package:comfy_list/features/appointments/domain/entities/repeat_rule.dart';
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
        reminderMinutes: const [30],
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

    group('regla de repetición', () {
      const rule = RepeatRule(interval: 2, unit: RepeatUnit.month);

      Map<String, dynamic> document(Map<String, dynamic> extra) => {
            'name':
                'projects/p/databases/(default)/documents/users/u1/appointments/a1',
            'fields': FirestoreValueCodec.encodeFields(<String, dynamic>{
              'title': 'Dentista',
              'isDone': false,
              ...extra,
            })['fields'],
          };

      test('fromDocument lee la regla de dos campos planos', () {
        final appointment = AppointmentDto.fromDocument(
          document({'repeatInterval': 2, 'repeatUnit': 'month'}),
        );

        expect(appointment.repeatRule, rule);
      });

      test('un documento sin los campos es una cita no recurrente', () {
        expect(AppointmentDto.fromDocument(document({})).repeatRule, isNull);
      });

      test('una regla a medias o inválida se lee como no recurrente', () {
        for (final extra in <Map<String, dynamic>>[
          {'repeatInterval': 2},
          {'repeatUnit': 'month'},
          {'repeatInterval': 0, 'repeatUnit': 'month'},
          {'repeatInterval': 2, 'repeatUnit': 'fortnight'},
        ]) {
          expect(
            AppointmentDto.fromDocument(document(extra)).repeatRule,
            isNull,
            reason: '$extra',
          );
        }
      });

      test('toCreateBody guarda la regla y sin regla no escribe nada', () {
        final withRule = FirestoreValueCodec.decodeFields(
          AppointmentDto.toCreateBody(
            title: 'Dentista',
            reminderMinutes: const [30],
            dateTime: DateTime.utc(2026, 6, 1, 9),
            repeatRule: rule,
            now: DateTime.utc(2026),
          ),
        );
        final without = FirestoreValueCodec.decodeFields(
          AppointmentDto.toCreateBody(
            title: 'Dentista',
            reminderMinutes: const [30],
            dateTime: DateTime.utc(2026, 6, 1, 9),
            now: DateTime.utc(2026),
          ),
        );

        expect(withRule['repeatInterval'], 2);
        expect(withRule['repeatUnit'], 'month');
        expect(without.containsKey('repeatInterval'), isFalse);
        expect(without.containsKey('repeatUnit'), isFalse);
      });

      test('toRestoreBody devuelve la regla de la cita', () {
        final appointment = Appointment(
          id: 'a1',
          title: 'Dentista',
          dateTime: DateTime.utc(2026, 6, 1, 9),
          isDone: false,
          createdAt: DateTime.utc(2026, 1, 1),
          updatedAt: DateTime.utc(2026, 1, 1),
          reminderMinutes: const [30],
          repeatRule: rule,
        );

        final decoded = FirestoreValueCodec.decodeFields(
          AppointmentDto.toRestoreBody(appointment),
        );

        expect(decoded['repeatInterval'], 2);
        expect(decoded['repeatUnit'], 'month');
      });

      test('toPatchBody con una regla anota sus dos campos en la máscara', () {
        final (body, mask) = AppointmentDto.toPatchBody(
          repeatRule: rule,
          now: DateTime.utc(2026),
        );

        expect(mask, containsAll(['repeatInterval', 'repeatUnit']));
        final decoded = FirestoreValueCodec.decodeFields(body);
        expect(decoded['repeatInterval'], 2);
        expect(decoded['repeatUnit'], 'month');
      });

      test('toPatchBody con clearRepeatRule borra los dos campos', () {
        final (body, mask) = AppointmentDto.toPatchBody(
          clearRepeatRule: true,
          now: DateTime.utc(2026),
        );

        expect(mask, containsAll(['repeatInterval', 'repeatUnit']));
        final fields = body['fields'] as Map<String, dynamic>;
        expect(fields['repeatInterval'], {'nullValue': null});
        expect(fields['repeatUnit'], {'nullValue': null});
      });

      test('toPatchBody sin tocar la regla no la menciona', () {
        final (_, mask) = AppointmentDto.toPatchBody(
          isDone: true,
          now: DateTime.utc(2026),
        );

        expect(mask, isNot(contains('repeatInterval')));
        expect(mask, isNot(contains('repeatUnit')));
      });
    });

    group('recordatorios', () {
      Map<String, dynamic> document(Map<String, dynamic> extra) => {
            'name':
                'projects/p/databases/(default)/documents/users/u1/appointments/a1',
            'fields': FirestoreValueCodec.encodeFields(<String, dynamic>{
              'title': 'Dentista',
              'isDone': false,
              ...extra,
            })['fields'],
          };

      test('fromDocument lee los márgenes guardados', () {
        final appointment = AppointmentDto.fromDocument(
          document({'reminderMinutes': '1440,60'}),
        );

        expect(appointment.reminderMinutes, [60, 1440]);
      });

      test('un documento anterior a los márgenes por cita avisa a los 30 min',
          () {
        expect(
          AppointmentDto.fromDocument(document({})).reminderMinutes,
          [30],
        );
      });

      test('el texto vacío es una cita sin avisos, no una antigua', () {
        expect(
          AppointmentDto.fromDocument(
            document({'reminderMinutes': ''}),
          ).reminderMinutes,
          isEmpty,
        );
      });

      test('toCreateBody guarda los márgenes y sin ninguno escribe el vacío',
          () {
        Map<String, dynamic> create(List<int> minutes) =>
            FirestoreValueCodec.decodeFields(
              AppointmentDto.toCreateBody(
                title: 'Dentista',
                dateTime: DateTime.utc(2026, 6, 1, 9),
                reminderMinutes: minutes,
                now: DateTime.utc(2026),
              ),
            );

        expect(create([60, 1440])['reminderMinutes'], '60,1440');
        expect(create(const []), containsPair('reminderMinutes', ''));
      });

      test('toRestoreBody devuelve los márgenes de la cita, también vacíos', () {
        Map<String, dynamic> restore(List<int> minutes) =>
            FirestoreValueCodec.decodeFields(
              AppointmentDto.toRestoreBody(
                Appointment(
                  id: 'a1',
                  title: 'Dentista',
                  dateTime: DateTime.utc(2026, 6, 1, 9),
                  isDone: false,
                  createdAt: DateTime.utc(2026),
                  updatedAt: DateTime.utc(2026),
                  reminderMinutes: minutes,
                ),
              ),
            );

        expect(restore([0, 30])['reminderMinutes'], '0,30');
        expect(restore(const []), containsPair('reminderMinutes', ''));
      });

      test('toPatchBody escribe los márgenes y vaciarlos no borra el campo',
          () {
        final (body, mask) = AppointmentDto.toPatchBody(
          reminderMinutes: const [],
          now: DateTime.utc(2026),
        );

        // Un campo borrado se leería como cita antigua y volvería a los 30 min.
        expect(mask, contains('reminderMinutes'));
        expect(
          FirestoreValueCodec.decodeFields(body),
          containsPair('reminderMinutes', ''),
        );
      });

      test('toPatchBody sin márgenes no los toca', () {
        final (_, mask) = AppointmentDto.toPatchBody(
          isDone: true,
          now: DateTime.utc(2026),
        );

        expect(mask, isNot(contains('reminderMinutes')));
      });
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
