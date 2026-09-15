import 'package:flutter/foundation.dart';

import '../../../../shared/data/notifications/notifications_service.dart';
import '../../../settings/domain/entities/app_settings.dart';
import '../../domain/entities/appointment.dart';
import 'appointment_reminder.dart';

/// Vuelca en el servicio de notificaciones los recordatorios que tocan.
class AppointmentRemindersScheduler {
  AppointmentRemindersScheduler(this._notifications);

  final NotificationsService _notifications;

  /// Último plan volcado. El polling entrega la misma lista cada pocos
  /// segundos, y sin esto cada tick reescribiría los avisos.
  List<AppointmentReminder>? _lastPlan;

  /// Rehace el plan entero: quita los avisos pendientes y programa los de
  /// [items].
  ///
  /// Se reescribe todo en lugar de calcular altas y bajas porque el resultado
  /// así no depende de lo que quedara programado antes (en otra sesión, o de
  /// antes de reiniciar el dispositivo).
  Future<void> sync({
    required List<Appointment> items,
    required AppSettings settings,
    required DateTime now,
  }) async {
    final reminders = buildAppointmentReminders(
      items: items,
      settings: settings,
      now: now,
    );
    if (listEquals(reminders, _lastPlan)) return;

    await _notifications.cancelAll();
    for (final reminder in reminders) {
      await _notifications.schedule(
        id: reminder.id,
        title: reminder.title,
        body: reminder.body,
        when: reminder.when,
      );
    }
    _lastPlan = reminders;
  }
}
