import 'package:comfy_list/features/appointments/data/reminders/appointment_reminder.dart';
import 'package:comfy_list/features/appointments/data/reminders/appointment_reminders_scheduler.dart';
import 'package:comfy_list/features/appointments/domain/entities/appointment.dart';
import 'package:comfy_list/features/settings/domain/entities/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../../../helpers/fake_notifications_service.dart';
import '../../../../helpers/test_helpers.dart';

void main() {
  setUpAll(() async {
    // El cuerpo del aviso formatea la hora en es_ES.
    await initializeDateFormatting('es_ES');
  });

  final now = DateTime(2026, 9, 15, 10);
  final item = buildAppointment(id: 'a1', dateTime: DateTime(2026, 9, 15, 12));

  late FakeNotificationsService notifications;
  late AppointmentRemindersScheduler scheduler;

  setUp(() {
    notifications = FakeNotificationsService();
    scheduler = AppointmentRemindersScheduler(notifications);
  });

  Future<void> sync({
    List<Appointment> items = const [],
    AppSettings? settings,
  }) {
    return scheduler.sync(
      items: items,
      settings: settings ?? buildAppSettings(),
      now: now,
    );
  }

  test('programa el aviso de cada cita futura', () async {
    await sync(items: [item]);

    expect(notifications.scheduled, hasLength(1));
    expect(notifications.scheduled.single.title, 'Dentista');
    expect(notifications.scheduled.single.when, DateTime(2026, 9, 15, 11, 30));
    expect(notifications.scheduled.single.id, notificationIdFor('a1'));
  });

  test('con las notificaciones apagadas solo limpia lo programado', () async {
    await sync(
      items: [item],
      settings: buildAppSettings(notificationsEnabled: false),
    );

    expect(notifications.cancelCalls, 1);
    expect(notifications.scheduled, isEmpty);
  });

  test('no vuelve a tocar el plugin si el plan no ha cambiado', () async {
    await sync(items: [item]);
    await sync(items: [item]);

    expect(notifications.cancelCalls, 1);
    expect(notifications.scheduled, hasLength(1));
  });

  test('reescribe cuando cambia el margen', () async {
    await sync(items: [item]);
    await sync(
      items: [item],
      settings: buildAppSettings(
        appointmentReminderLead: AppointmentReminderLead.oneHour,
      ),
    );

    expect(notifications.cancelCalls, 2);
    expect(notifications.scheduled.single.when, DateTime(2026, 9, 15, 11));
  });
}
