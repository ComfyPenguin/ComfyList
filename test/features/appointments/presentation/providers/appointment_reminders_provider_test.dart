import 'package:comfy_list/features/appointments/domain/entities/appointment.dart';
import 'package:comfy_list/features/appointments/presentation/providers/appointment_reminders_provider.dart';
import 'package:comfy_list/features/appointments/presentation/providers/appointments_provider.dart';
import 'package:comfy_list/features/appointments/presentation/providers/appointments_state.dart';
import 'package:comfy_list/features/settings/domain/entities/app_settings.dart';
import 'package:comfy_list/features/settings/domain/repositories/settings_repository.dart';
import 'package:comfy_list/features/settings/presentation/providers/settings_provider.dart';
import 'package:comfy_list/shared/data/notifications/notifications_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../../../helpers/fake_notifications_service.dart';
import '../../../../helpers/fake_settings_repository.dart';
import '../../../../helpers/provider_scope.dart';
import '../../../../helpers/test_helpers.dart';

/// Notifier de citas con una lista fija: sin repo ni auth de por medio.
class _FixedAppointmentsNotifier extends AppointmentsNotifier {
  _FixedAppointmentsNotifier(this.items);

  final List<Appointment> items;

  @override
  AppointmentsState build() => AppointmentsData(items);
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es_ES');
  });

  test('programa los avisos al llegar las citas y los ajustes', () async {
    final notifications = FakeNotificationsService();
    final repo = FakeSettingsRepository(
      settings: buildAppSettings(
        notificationsEnabled: true,
        appointmentReminderLead: AppointmentReminderLead.oneHour,
      ),
    );
    addTearDown(repo.close);

    // Bien dentro del margen: el aviso tiene que caer en el futuro.
    final items = [
      buildAppointment(
        id: 'a1',
        title: 'Análisis',
        dateTime: DateTime.now().add(const Duration(hours: 3)),
      ),
    ];

    final container = createTestContainer(
      repositoryOverrides: {SettingsRepository: repo},
      extra: [
        notificationsServiceProvider.overrideWithValue(notifications),
        appointmentsProvider.overrideWith(
          () => _FixedAppointmentsNotifier(items),
        ),
      ],
    );

    // Activar el provider es lo que hace `app.dart`.
    container.listen(appointmentRemindersProvider, (_, _) {});
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(notifications.scheduled, hasLength(1));
    expect(notifications.scheduled.single.title, 'Análisis');

    // Apagar las notificaciones vuelve a sincronizar y retira lo programado.
    await container
        .read(settingsProvider.notifier)
        .setNotificationsEnabled(false);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(notifications.scheduled, isEmpty);
    expect(notifications.cancelCalls, greaterThan(0));
  });

  test('al conceder las alarmas exactas reescribe los avisos', () async {
    final notifications = FakeNotificationsService()
      ..exactAlarmsGranted = false;
    final repo = FakeSettingsRepository(
      settings: buildAppSettings(notificationsEnabled: true),
    );
    addTearDown(repo.close);

    final items = [
      buildAppointment(
        id: 'a1',
        title: 'Análisis',
        dateTime: DateTime.now().add(const Duration(hours: 3)),
      ),
    ];

    final container = createTestContainer(
      repositoryOverrides: {SettingsRepository: repo},
      extra: [
        notificationsServiceProvider.overrideWithValue(notifications),
        appointmentsProvider.overrideWith(
          () => _FixedAppointmentsNotifier(items),
        ),
      ],
    );

    container.listen(appointmentRemindersProvider, (_, _) {});
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(notifications.scheduleCalls, 1);
    expect(container.read(exactAlarmsGrantedProvider).value, isFalse);

    // El usuario lo concede en los ajustes del sistema y la app vuelve a
    // preguntar: los avisos ya programados quedaron en modo aproximado, así que
    // hay que volver a escribirlos aunque el plan sea el mismo.
    notifications.exactAlarmsGranted = true;
    container.invalidate(exactAlarmsGrantedProvider);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(notifications.scheduleCalls, 2);
  });

  test('sin citas cargadas no toca el servicio', () async {
    final notifications = FakeNotificationsService();
    final repo = FakeSettingsRepository();
    addTearDown(repo.close);

    // Sin sesión las citas se quedan en [AppointmentsInitial]: los ajustes
    // llegan, pero no hay plan que volcar.
    final container = createTestContainer(
      repositoryOverrides: {SettingsRepository: repo},
      extra: [notificationsServiceProvider.overrideWithValue(notifications)],
    );

    container.listen(appointmentRemindersProvider, (_, _) {});
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(notifications.scheduled, isEmpty);
    expect(notifications.cancelCalls, 0);
  });
}
