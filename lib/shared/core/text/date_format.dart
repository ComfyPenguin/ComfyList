import 'package:intl/intl.dart';

import 'capitalize.dart';

/// Fecha larga en español, con día y mes en mayúscula inicial:
/// «Miércoles, 30 de Septiembre de 2026».
///
/// Requiere `initializeDateFormatting('es_ES')`, que ya hace `main()`.
String formatLongDate(DateTime date) {
  final dayName = capitalize(DateFormat('EEEE', 'es_ES').format(date));
  final monthName = capitalize(DateFormat('MMMM', 'es_ES').format(date));
  return '$dayName, ${date.day} de $monthName de ${date.year}';
}
