/// Cómo se lee un margen ya puesto: «10 min», «1 h», «3 días».
///
/// El cero ya no se ofrece —el aviso a la hora de la cita se quitó de los
/// presets—, pero sigue leyéndose así: es el margen que quedó guardado en quien
/// lo tuviera puesto.
String formatReminderLead(int minutes) {
  if (minutes <= 0) return 'A la hora';
  if (minutes % 1440 == 0) {
    final days = minutes ~/ 1440;
    return days == 1 ? '1 día' : '$days días';
  }
  if (minutes % 60 == 0) return '${minutes ~/ 60} h';
  return '$minutes min';
}

/// Cómo se ofrece un margen en el menú de añadir: «5 minutos antes», «1 hora
/// antes». Ahí hay sitio para decirlo entero.
String formatReminderLeadBefore(int minutes) {
  if (minutes % 1440 == 0) {
    final days = minutes ~/ 1440;
    return days == 1 ? '1 día antes' : '$days días antes';
  }
  if (minutes % 60 == 0) {
    final hours = minutes ~/ 60;
    return hours == 1 ? '1 hora antes' : '$hours horas antes';
  }
  return '$minutes minutos antes';
}
