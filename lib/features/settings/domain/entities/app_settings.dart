import 'package:flutter/material.dart';

/// Cuántos recordatorios puede llevar una cita.
const int maxAppointmentReminders = 3;

/// Configuración local de la app (tema y preferencias de usuario).
@immutable
class AppSettings {
  const AppSettings({
    required this.themeMode,
    required this.notificationsEnabled,
    required this.appointmentsCompletionEnabled,
    required this.completedToBottom,
    required this.appointmentsCompletedToBottom,
    required this.appointmentsTodayOnTop,
    required this.invertSwipeActions,
    required this.use24HourFormat,
    required this.appointmentReminderMinutes,
  });

  final ThemeMode themeMode;

  /// Avisos de citas. Apagado de fábrica, como en `SettingsTable`: el permiso
  /// del sistema se pide al encenderlo.
  final bool notificationsEnabled;

  final bool appointmentsCompletionEnabled;

  /// Si es `true`, las tareas completadas se mueven al final de la lista.
  final bool completedToBottom;

  /// Si es `true`, las citas completadas se mueven al final de su día.
  final bool appointmentsCompletedToBottom;

  /// Si es `true`, el día de hoy va primero en la lista de citas, aunque haya
  /// días pasados por delante.
  final bool appointmentsTodayOnTop;

  /// Si es `true`, las acciones del deslizamiento se invierten: eliminar a la
  /// izquierda y completar a la derecha (por defecto es al revés).
  final bool invertSwipeActions;

  /// Si es `true`, las horas de las citas se muestran en formato 24H.
  /// Si es `false`, se muestran en formato 12H con AM/PM.
  final bool use24HourFormat;

  /// Márgenes con los que avisa una cita, en minutos antes de su hora (0 = a su
  /// hora). Sin márgenes no hay ningún aviso. La forma canónica la deja
  /// [normalizeReminderMinutes]: sin repetidos, de menor a mayor y como mucho
  /// [maxAppointmentReminders].
  final List<int> appointmentReminderMinutes;

  static const AppSettings defaults = AppSettings(
    themeMode: ThemeMode.system,
    notificationsEnabled: false,
    appointmentsCompletionEnabled: false,
    completedToBottom: true,
    appointmentsCompletedToBottom: true,
    appointmentsTodayOnTop: true,
    invertSwipeActions: false,
    use24HourFormat: true,
    appointmentReminderMinutes: [30],
  );

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? notificationsEnabled,
    bool? appointmentsCompletionEnabled,
    bool? completedToBottom,
    bool? appointmentsCompletedToBottom,
    bool? appointmentsTodayOnTop,
    bool? invertSwipeActions,
    bool? use24HourFormat,
    List<int>? appointmentReminderMinutes,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      appointmentsCompletionEnabled:
          appointmentsCompletionEnabled ?? this.appointmentsCompletionEnabled,
      completedToBottom: completedToBottom ?? this.completedToBottom,
      appointmentsCompletedToBottom:
          appointmentsCompletedToBottom ?? this.appointmentsCompletedToBottom,
      appointmentsTodayOnTop:
          appointmentsTodayOnTop ?? this.appointmentsTodayOnTop,
      invertSwipeActions: invertSwipeActions ?? this.invertSwipeActions,
      use24HourFormat: use24HourFormat ?? this.use24HourFormat,
      appointmentReminderMinutes:
          appointmentReminderMinutes ?? this.appointmentReminderMinutes,
    );
  }

  static ThemeMode parseThemeMode(String value) => switch (value) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };

  static String themeModeToString(ThemeMode mode) => switch (mode) {
    ThemeMode.light => 'light',
    ThemeMode.dark => 'dark',
    ThemeMode.system => 'system',
  };

  /// Forma canónica de los márgenes. Al recortar al máximo se quedan los más
  /// cercanos a la cita, que son los que primero suenan.
  static List<int> normalizeReminderMinutes(Iterable<int> minutes) {
    final canonical = minutes.where((lead) => lead >= 0).toSet().toList()
      ..sort();
    return canonical.length > maxAppointmentReminders
        ? canonical.sublist(0, maxAppointmentReminders)
        : canonical;
  }

  /// Márgenes tal como se guardan: la lista canónica separada por comas.
  static String reminderMinutesToString(List<int> minutes) =>
      normalizeReminderMinutes(minutes).join(',');

  /// Márgenes guardados. Un valor vacío es «sin avisos» y lo que no se pueda
  /// leer se descarta.
  static List<int> parseReminderMinutes(String value) =>
      normalizeReminderMinutes(
        value.split(',').map(int.tryParse).whereType<int>(),
      );
}

/// Margen de un aviso que ofrece Ajustes, en minutos antes de la hora.
///
/// El personalizado no vive aquí: cualquier cantidad que no sea de estos sale
/// como [customReminderMinutes].
enum AppointmentReminderPreset {
  fiveMinutes(5),
  tenMinutes(10),
  thirtyMinutes(30),
  oneHour(60),
  oneDay(1440);

  const AppointmentReminderPreset(this.minutes);

  final int minutes;
}

/// Márgenes de [minutes] con [lead] encendido o apagado, en su forma canónica.
List<int> toggleReminderMinutes(List<int> minutes, int lead) {
  final next = minutes.toList();
  if (next.contains(lead)) {
    next.remove(lead);
  } else {
    next.add(lead);
  }
  return AppSettings.normalizeReminderMinutes(next);
}

/// El margen personalizado de [minutes]: el que no es ninguno de los presets.
/// `null` si todos los que hay salen en Ajustes.
int? customReminderMinutes(List<int> minutes) {
  for (final lead in minutes) {
    if (!_isPresetMinutes(lead)) return lead;
  }
  return null;
}

/// Deja el personalizado en [lead]: el margen personalizado es uno solo, así que
/// sale el que hubiera y entra el nuevo. Si el elegido es uno de los presets,
/// solo se enciende ese y desaparece el personalizado.
List<int> setCustomReminderMinutes(List<int> minutes, int lead) {
  final presets = minutes.where(_isPresetMinutes);
  return AppSettings.normalizeReminderMinutes([...presets, lead]);
}

bool _isPresetMinutes(int minutes) =>
    AppointmentReminderPreset.values.any((preset) => preset.minutes == minutes);
