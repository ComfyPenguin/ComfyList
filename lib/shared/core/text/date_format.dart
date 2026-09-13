import 'package:intl/intl.dart';

import 'capitalize.dart';

/// Fecha larga en español, con día y mes en mayúscula inicial:
/// «Miércoles, 30 Septiembre 2026».
///
/// Requiere `initializeDateFormatting('es_ES')`, que ya hace `main()`.
String formatLongDate(DateTime date) {
  final dayName = capitalize(DateFormat('EEEE', 'es_ES').format(date));
  final monthName = capitalize(DateFormat('MMMM', 'es_ES').format(date));
  return '$dayName, ${date.day} $monthName ${date.year}';
}

/// Hora del día según el ajuste del usuario: «14:30» en 24 h y «02:30» en 12 h.
String formatClockTime(DateTime time, {required bool use24HourFormat}) =>
    DateFormat(use24HourFormat ? 'HH:mm' : 'hh:mm', 'es_ES').format(time);

/// Sufijo del periodo («AM»/«PM») en 12 h, o cadena vacía en 24 h.
///
/// `DateFormat('a')` en español devuelve «a. m.», así que se normaliza a la
/// forma compacta que usan las tiles.
String formatClockPeriod(DateTime time, {required bool use24HourFormat}) {
  if (use24HourFormat) return '';
  return DateFormat('a', 'es_ES')
      .format(time)
      .toUpperCase()
      .replaceAll(RegExp(r'\s+'), '')
      .replaceAll('.', '');
}

/// Hora en una sola línea: «14:30» o «02:30 AM».
String formatClockTimeWithPeriod(
  DateTime time, {
  required bool use24HourFormat,
}) {
  final clock = formatClockTime(time, use24HourFormat: use24HourFormat);
  final period = formatClockPeriod(time, use24HourFormat: use24HourFormat);
  return period.isEmpty ? clock : '$clock $period';
}
