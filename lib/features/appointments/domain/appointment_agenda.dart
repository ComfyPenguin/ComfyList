import 'entities/appointment.dart';

/// Un día de la agenda con sus citas, ya en el orden en que se enseñan.
typedef AgendaDay = ({DateTime date, List<Appointment> appointments});

/// Día siguiente. Constructor en vez de sumar 24 h: en los cambios de hora el
/// día siguiente no cae justo a medianoche.
DateTime dayAfter(DateTime date) =>
    DateTime(date.year, date.month, date.day + 1);

/// Ordena las citas por fecha ascendente (las más próximas primero). Con
/// [completedToBottom] las completadas van al final de su día.
List<Appointment> sortAppointments(
  Iterable<Appointment> appointments, {
  required bool completedToBottom,
}) =>
    [...appointments]..sort((a, b) {
        if (completedToBottom && a.isDone != b.isDone) {
          return a.isDone ? 1 : -1;
        }
        return a.dateTime.compareTo(b.dateTime);
      });

/// Reparte [sorted] por días, de menor a mayor, conservando el orden de las
/// citas dentro de cada día.
///
/// Con [todayOnTop], hoy ([today], a medianoche) sube al principio y mañana
/// queda justo debajo; sin esto los días pasados se colarían entre los dos,
/// porque el resto va en ascendente. Si hoy no tiene citas, no se mueve nada.
List<AgendaDay> groupByDay(
  List<Appointment> sorted, {
  required bool todayOnTop,
  required DateTime today,
}) {
  final byDate = <DateTime, List<Appointment>>{};
  for (final appointment in sorted) {
    final d = appointment.dateTime;
    byDate.putIfAbsent(DateTime(d.year, d.month, d.day), () => []).add(
          appointment,
        );
  }

  final dates = byDate.keys.toList()..sort();
  if (todayOnTop) {
    final todayIndex = dates.indexOf(today);
    if (todayIndex >= 0) {
      if (todayIndex > 0) dates.insert(0, dates.removeAt(todayIndex));

      final tomorrowIndex = dates.indexOf(dayAfter(today));
      if (tomorrowIndex > 1) dates.insert(1, dates.removeAt(tomorrowIndex));
    }
  }

  return [for (final date in dates) (date: date, appointments: byDate[date]!)];
}
