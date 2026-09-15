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

  /// Deja programados los avisos que tocan para [items].
  ///
  /// El primer volcado de la sesión limpia todo lo programado, de modo que el
  /// resultado no depende de lo que dejara otra sesión o de antes de reiniciar
  /// el dispositivo. A partir de ahí se quita aviso por aviso: lo que sale del
  /// plan casi siempre es un aviso que ya llegó a su hora, y esos no se tocan.
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

    await _discard(previous: _lastPlan, planned: reminders, now: now);
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

  /// Quita lo que sobraba del plan anterior.
  ///
  /// Un aviso sale del plan en cuanto llega su hora, y en ese momento el
  /// sistema puede tenerlo todavía pendiente (una alarma aproximada nunca se
  /// adelanta): cancelarlo ahí es lo que lo deja sin sonar. Por eso los ya
  /// vencidos se dejan en paz y solo se quitan los que aún estaban por llegar.
  Future<void> _discard({
    required List<AppointmentReminder>? previous,
    required List<AppointmentReminder> planned,
    required DateTime now,
  }) async {
    if (previous == null) {
      await _notifications.cancelAll();
      return;
    }

    final plannedIds = {for (final reminder in planned) reminder.id};
    for (final reminder in previous) {
      if (plannedIds.contains(reminder.id)) continue;
      if (!reminder.when.isAfter(now)) continue;
      await _notifications.cancel(reminder.id);
    }
  }
}
