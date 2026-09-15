import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/core/time/clock.dart';
import '../../../../shared/data/notifications/notifications_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../settings/presentation/providers/settings_state.dart';
import '../../data/reminders/appointment_reminders_scheduler.dart';
import 'appointments_provider.dart';
import 'appointments_state.dart';

final appointmentRemindersSchedulerProvider =
    Provider<AppointmentRemindersScheduler>(
      (ref) => AppointmentRemindersScheduler(
        ref.watch(notificationsServiceProvider),
      ),
    );

/// Mantiene los recordatorios de citas al día.
///
/// No tiene estado propio: escucha las citas y los ajustes y vuelca el plan que
/// toca en el servicio de notificaciones. Lo activa `app.dart`, así que hay un
/// único sincronizador para toda la app. Mientras falte cualquiera de los dos
/// estados no hace nada — al llegar, los propios listeners vuelven a avisar.
final appointmentRemindersProvider = Provider<void>((ref) {
  final scheduler = ref.watch(appointmentRemindersSchedulerProvider);

  void sync() {
    final items = switch (ref.read(appointmentsProvider)) {
      AppointmentsData(:final items) => items,
      _ => null,
    };
    final settings = switch (ref.read(settingsProvider)) {
      SettingsData(:final settings) => settings,
      _ => null,
    };
    if (items == null || settings == null) return;

    unawaited(
      scheduler.sync(
        items: items,
        settings: settings,
        now: ref.read(clockProvider)(),
      ),
    );
  }

  ref.listen(appointmentsProvider, (_, _) => sync());
  ref.listen(settingsProvider, (_, _) => sync());
  sync();
});
