import 'package:comfy_list/features/appointments/data/reminders/appointment_reminder.dart';
import 'package:comfy_list/features/settings/domain/entities/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  setUpAll(() async {
    // Los avisos formatean la hora en es_ES, como el resto de la app.
    await initializeDateFormatting('es_ES');
  });

  // Fecha fija: el plan recibe «ahora», así que el test no depende del reloj.
  final now = DateTime(2026, 9, 15, 10);

  group('buildAppointmentReminders', () {
    test('con las notificaciones apagadas no hay ningún aviso', () {
      final reminders = buildAppointmentReminders(
        items: [buildAppointment(dateTime: DateTime(2026, 9, 15, 12))],
        settings: buildAppSettings(notificationsEnabled: false),
        now: now,
      );

      expect(reminders, isEmpty);
    });

    test('programa el aviso con el margen guardado', () {
      final reminders = buildAppointmentReminders(
        items: [
          buildAppointment(id: 'a1', dateTime: DateTime(2026, 9, 15, 12)),
        ],
        settings: buildAppSettings(
          notificationsEnabled: true,
          appointmentReminderLead: AppointmentReminderLead.tenMinutes,
        ),
        now: now,
      );

      expect(reminders, hasLength(1));
      expect(reminders.single.when, DateTime(2026, 9, 15, 11, 50));
    });

    test('deja fuera las citas completadas', () {
      final reminders = buildAppointmentReminders(
        items: [
          buildAppointment(
            id: 'hecha',
            dateTime: DateTime(2026, 9, 15, 12),
            isDone: true,
          ),
        ],
        settings: buildAppSettings(notificationsEnabled: true),
        now: now,
      );

      expect(reminders, isEmpty);
    });

    test('deja fuera los avisos cuyo momento ya pasó', () {
      final reminders = buildAppointmentReminders(
        items: [
          // A las 10:15 con un margen de 30 min el aviso caería a las 9:45.
          buildAppointment(
            id: 'inminente',
            dateTime: DateTime(2026, 9, 15, 10, 1),
          ),
          buildAppointment(id: 'pasada', dateTime: DateTime(2026, 9, 15, 9)),
        ],
        settings: buildAppSettings(notificationsEnabled: true),
        now: now,
      );

      expect(reminders, isEmpty);
    });

    test('describe el día y la hora de la cita, con la ubicación detrás', () {
      final reminders = buildAppointmentReminders(
        items: [
          buildAppointment(
            id: 'hoy',
            title: 'Análisis',
            dateTime: DateTime(2026, 9, 15, 12, 30),
            location: 'Calle Mayor 1',
          ),
          buildAppointment(id: 'manana', dateTime: DateTime(2026, 9, 16, 9, 5)),
        ],
        settings: buildAppSettings(notificationsEnabled: true),
        now: now,
      );

      expect(reminders.first.title, 'Análisis');
      expect(reminders.first.body, 'Hoy a las 12:30 · Calle Mayor 1');
      expect(reminders[1].body, 'Mañana a las 09:05');
    });

    test('respeta el formato de 12 h en el aviso', () {
      final reminders = buildAppointmentReminders(
        items: [buildAppointment(dateTime: DateTime(2026, 9, 15, 14, 30))],
        settings: buildAppSettings(
          notificationsEnabled: true,
          use24HourFormat: false,
        ),
        now: now,
      );

      expect(reminders.single.body, 'Hoy a las 02:30 PM');
    });
  });

  group('notificationIdFor', () {
    test('es estable para el mismo id de documento', () {
      expect(notificationIdFor('a1'), notificationIdFor('a1'));
    });

    test('cabe en el rango de 32 bits que admite el plugin', () {
      for (final id in ['a1', '', 'documento-largo-con-acentos-áéíóú']) {
        final value = notificationIdFor(id);
        expect(value, greaterThanOrEqualTo(0));
        expect(value, lessThanOrEqualTo(0x7fffffff));
      }
    });

    test('separa ids distintos', () {
      expect(notificationIdFor('a1'), isNot(notificationIdFor('a2')));
    });
  });
}
