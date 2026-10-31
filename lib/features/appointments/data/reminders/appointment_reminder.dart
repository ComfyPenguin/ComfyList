import 'package:flutter/foundation.dart';

import '../../../../shared/core/text/date_format.dart';
import '../../../settings/domain/entities/app_settings.dart';
import '../../domain/entities/appointment.dart';

/// Aviso que tiene que quedar programado para una cita.
@immutable
class AppointmentReminder {
  const AppointmentReminder({
    required this.id,
    required this.title,
    required this.body,
    required this.when,
  });

  /// Id con el que el plugin identifica el aviso.
  final int id;

  final String title;
  final String body;

  /// Momento local en el que debe saltar.
  final DateTime when;

  @override
  bool operator ==(Object other) =>
      other is AppointmentReminder &&
      other.id == id &&
      other.title == title &&
      other.body == body &&
      other.when == when;

  @override
  int get hashCode => Object.hash(id, title, body, when);
}

/// Avisos que corresponden a [items]: una cita avisa una vez por cada uno de
/// sus propios márgenes.
///
/// Con las notificaciones apagadas en [settings] no hay ninguno. De cada cita
/// se caen las ya completadas y los avisos que ya habrían pasado (una cita
/// dentro de 10 minutos con un margen de 30): el plugin rechaza programar en el
/// pasado y soltar el aviso al abrir la app sería ruido.
List<AppointmentReminder> buildAppointmentReminders({
  required List<Appointment> items,
  required AppSettings settings,
  required DateTime now,
}) {
  if (!settings.notificationsEnabled) return const [];

  final reminders = <AppointmentReminder>[];
  for (final item in items) {
    if (item.isDone) continue;
    for (final minutes in item.reminderMinutes) {
      final when = item.dateTime.subtract(Duration(minutes: minutes));
      if (!when.isAfter(now)) continue;
      reminders.add(
        AppointmentReminder(
          id: notificationIdFor(item.id, minutes: minutes),
          title: item.title,
          body: _bodyFor(
            item,
            now: now,
            use24HourFormat: settings.use24HourFormat,
          ),
          when: when,
        ),
      );
    }
  }
  return reminders;
}

/// Id numérico estable a partir del id del documento y del margen del aviso.
///
/// Una cita lleva un aviso por margen y se cancelan por id, así que cada margen
/// necesita el suyo. `String.hashCode` no está garantizado entre ejecuciones,
/// así que va un FNV-1a de 32 bits recortado al rango positivo que admite el
/// plugin.
int notificationIdFor(String appointmentId, {required int minutes}) {
  var hash = 0x811c9dc5;
  for (final unit in '$appointmentId:$minutes'.codeUnits) {
    hash = (hash ^ unit) * 0x01000193 & 0xffffffff;
  }
  return hash & 0x7fffffff;
}

String _bodyFor(
  Appointment item, {
  required DateTime now,
  required bool use24HourFormat,
}) {
  final time = formatClockTimeWithPeriod(
    item.dateTime,
    use24HourFormat: use24HourFormat,
  );
  final location = item.location;
  final where = location == null || location.isEmpty ? '' : ' · $location';
  return '${_dayLabel(item.dateTime, now)} a las $time$where';
}

/// Día de la cita respecto a «ahora», para que el aviso diga cuándo es. El
/// texto se calcula al programarlo, así que «Hoy» y «Mañana» solo aparecen
/// cuando el aviso suena ese mismo día o el siguiente.
String _dayLabel(DateTime date, DateTime now) {
  final day = DateTime(date.year, date.month, date.day);
  final today = DateTime(now.year, now.month, now.day);
  if (day == today) return 'Hoy';
  // Constructor en vez de sumar 24 h: en los cambios de hora el día siguiente
  // no cae justo a medianoche.
  if (day == DateTime(today.year, today.month, today.day + 1)) return 'Mañana';
  return formatLongDate(date);
}
