import 'package:flutter/material.dart';

/// Cuántos recordatorios puede llevar una cita.
const int maxAppointmentReminders = 5;/// Días que ofrece el ajuste de la papelera antes de vaciarla sola. `0` es
/// «nunca»: los borrados se quedan hasta que el usuario la vacíe a mano.
const List<int> trashRetentionDayOptions = [0, 7, 15, 30];

/// Días que aguanta la papelera de fábrica: un mes de margen antes de empezar a
/// vaciarse sola.
const int defaultTrashRetentionDays = 30;

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
    required this.longPressHintSeen,
    required this.trashRetentionDays,
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

  /// Si `true`, ya se mostró la pista de mantener pulsada una tarjeta para
  /// editarla. Se muestra una única vez.
  final bool longPressHintSeen;

  /// Días que aguanta un borrado en la papelera antes de que la app la vacíe
  /// sola: uno de [trashRetentionDayOptions], con `0` para «nunca». De fábrica
  /// [defaultTrashRetentionDays].
  final int trashRetentionDays;

  /// Si la papelera se vacía sola ([trashRetentionDays] distinto de «nunca»).
  bool get emptiesTrashItself => trashRetentionDays > 0;

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
    longPressHintSeen: false,
    trashRetentionDays: defaultTrashRetentionDays,
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
    bool? longPressHintSeen,
    int? trashRetentionDays,
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
      longPressHintSeen: longPressHintSeen ?? this.longPressHintSeen,
      trashRetentionDays: trashRetentionDays ?? this.trashRetentionDays,
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

  /// Un valor guardado que el ajuste no ofrece —otra versión de la app, una
  /// fila tocada a mano— cae a «nunca», para que el control tenga siempre una
  /// opción que marcar.
  static int parseTrashRetentionDays(int value) =>
      trashRetentionDayOptions.contains(value) ? value : defaultTrashRetentionDays;

  /// Márgenes guardados. Un valor vacío es «sin avisos» y lo que no se pueda
  /// leer se descarta.
  static List<int> parseReminderMinutes(String value) =>
      normalizeReminderMinutes(
        value.split(',').map(int.tryParse).whereType<int>(),
      );
}

/// Margen de un aviso que ofrece Ajustes, en minutos antes de la hora.
///
/// Lo que no salga de aquí se elige a mano en la rueda del personalizado.
enum AppointmentReminderPreset {
  fiveMinutes(5),
  tenMinutes(10),
  fifteenMinutes(15),
  thirtyMinutes(30),
  oneHour(60),
  oneDay(1440);

  const AppointmentReminderPreset(this.minutes);

  final int minutes;
}

/// Márgenes de [minutes] con [lead] añadido, en su forma canónica.
List<int> addReminderMinutes(List<int> minutes, int lead) =>
    AppSettings.normalizeReminderMinutes([...minutes, lead]);

/// Márgenes de [minutes] sin [lead].
List<int> removeReminderMinutes(List<int> minutes, int lead) =>
    minutes.where((minutes) => minutes != lead).toList();
