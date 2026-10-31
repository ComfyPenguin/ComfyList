import 'dart:math' as math;

import 'package:flutter/foundation.dart';

enum RepeatUnit { day, week, month, year }

/// Regla de repetición de una cita recurrente: «cada [interval] [unit]».
@immutable
class RepeatRule {
  const RepeatRule({required this.interval, required this.unit})
    : assert(interval >= 1);

  final int interval;
  final RepeatUnit unit;

  /// La regla guardada en [interval] y [unit] (el nombre de la unidad), o `null`
  /// si falta alguno o no es válido: un documento a medias o escrito por otra
  /// versión se lee como una cita no recurrente, no como un error.
  static RepeatRule? fromStored({
    required Object? interval,
    required Object? unit,
  }) {
    if (interval is! int || interval < 1) return null;
    final parsed = RepeatUnit.values.where((u) => u.name == unit).firstOrNull;
    return parsed == null ? null : RepeatRule(interval: interval, unit: parsed);
  }

  /// Primera fecha de la regla posterior a [now], contando desde [from] (la
  /// fecha actual de la cita, en hora local) de [interval] en [interval].
  ///
  /// Siempre es posterior a [from]: una cita futura completada antes de tiempo
  /// avanza un solo paso. Una atrasada salta las ocurrencias que ya pasaron.
  /// Dentro de una llamada las fechas se calculan siempre desde [from] y no de
  /// una a otra, así que al saltar varias ocurrencias un 31 recortado al 28 de
  /// febrero no arrastra el recorte a marzo.
  ///
  /// shortcut: entre una llamada y la siguiente sí se arrastra, porque la cita
  /// guarda la fecha ya recortada y no el día original: un mensual del 31 que se
  /// completa en febrero se queda en el 28 en las siguientes ocurrencias; si
  /// molesta, guardar el día ancla en la cita.
  DateTime nextAfter(DateTime from, {required DateTime now}) {
    for (var step = 1; ; step++) {
      final candidate = _occurrence(from, step * interval);
      if (candidate.isAfter(now)) return candidate;
    }
  }

  /// La fecha [count] unidades después de [from], a la misma hora local.
  DateTime _occurrence(DateTime from, int count) {
    switch (unit) {
      case RepeatUnit.day:
        return _atSameTime(from, from.year, from.month, from.day + count);
      case RepeatUnit.week:
        return _atSameTime(from, from.year, from.month, from.day + 7 * count);
      case RepeatUnit.month:
        return _addMonths(from, count);
      case RepeatUnit.year:
        return _addMonths(from, 12 * count);
    }
  }

  static DateTime _addMonths(DateTime from, int months) {
    final total = from.year * 12 + from.month - 1 + months;
    final year = total ~/ 12;
    final month = total % 12 + 1;
    // El día 0 del mes siguiente es el último de este.
    final lastDay = DateTime(year, month + 1, 0).day;
    return _atSameTime(from, year, month, math.min(from.day, lastDay));
  }

  static DateTime _atSameTime(DateTime from, int year, int month, int day) =>
      DateTime(year, month, day, from.hour, from.minute, from.second);

  @override
  bool operator ==(Object other) =>
      other is RepeatRule && other.interval == interval && other.unit == unit;

  @override
  int get hashCode => Object.hash(interval, unit);
}
