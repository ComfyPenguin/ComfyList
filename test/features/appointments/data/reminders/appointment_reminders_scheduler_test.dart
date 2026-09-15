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
    DateTime? at,
    bool force = false,
  }) {
    return scheduler.sync(
      items: items,
      settings: settings ?? buildAppSettings(),
      now: at ?? now,
      force: force,
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
    expect(notifications.scheduleCalls, 1);
    expect(notifications.scheduled, hasLength(1));
  });

  test('con force reescribe el plan aunque sea el mismo', () async {
    await sync(items: [item]);
    await sync(items: [item], force: true);

    // El mismo id se vuelve a programar —el plugin reemplaza el aviso— y no
    // hay nada que quitar, porque el aviso no ha salido del plan.
    expect(notifications.scheduleCalls, 2);
    expect(notifications.cancelled, isEmpty);
    expect(notifications.scheduled, hasLength(1));
  });

  test('al cambiar el margen reprograma el mismo aviso', () async {
    await sync(items: [item]);
    await sync(
      items: [item],
      settings: buildAppSettings(
        appointmentReminderLead: AppointmentReminderLead.oneHour,
      ),
    );

    // El id del aviso no cambia, así que el plugin reemplaza el anterior.
    expect(notifications.cancelled, isEmpty);
    expect(notifications.scheduled.single.when, DateTime(2026, 9, 15, 11));
  });

  test('quita los avisos que salen del plan y aún no han llegado', () async {
    await sync(items: [item]);
    await sync(items: []);

    expect(notifications.cancelled, [notificationIdFor('a1')]);
    expect(notifications.scheduled, isEmpty);
  });

  test('no cancela el aviso que ya ha llegado a su hora', () async {
    // Cita de aquí a un minuto con el aviso a su hora: el plan lo suelta en
    // cuanto pasa ese minuto, que es justo cuando el sistema puede tenerlo
    // todavía pendiente.
    final inminente = buildAppointment(
      id: 'a1',
      dateTime: now.add(const Duration(minutes: 1)),
    );
    final settings = buildAppSettings(
      appointmentReminderLead: AppointmentReminderLead.atTime,
    );

    await sync(items: [inminente], settings: settings);
    expect(notifications.scheduled, hasLength(1));

    await sync(
      items: [inminente],
      settings: settings,
      at: now.add(const Duration(minutes: 2)),
    );

    expect(notifications.cancelCalls, 1, reason: 'solo la limpieza inicial');
    expect(notifications.cancelled, isEmpty);
    expect(notifications.scheduled, hasLength(1));
  });
}
