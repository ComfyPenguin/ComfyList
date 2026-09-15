import 'package:flutter/material.dart';

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
    required this.appointmentReminderLead,
  });

  final ThemeMode themeMode;
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

  /// Cuánto antes de la cita suena el recordatorio.
  final AppointmentReminderLead appointmentReminderLead;

  static const AppSettings defaults = AppSettings(
    themeMode: ThemeMode.system,
    notificationsEnabled: true,
    appointmentsCompletionEnabled: false,
    completedToBottom: true,
    appointmentsCompletedToBottom: true,
    appointmentsTodayOnTop: true,
    invertSwipeActions: false,
    use24HourFormat: true,
    appointmentReminderLead: AppointmentReminderLead.thirtyMinutes,
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
    AppointmentReminderLead? appointmentReminderLead,
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
      appointmentReminderLead:
          appointmentReminderLead ?? this.appointmentReminderLead,
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
}

/// Margen con el que avisa el recordatorio de una cita, antes de su hora.
///
/// En la base de datos se guardan los minutos; el enum mantiene el conjunto
/// cerrado de opciones que ofrece Ajustes.
enum AppointmentReminderLead {
  atTime(0),
  tenMinutes(10),
  thirtyMinutes(30),
  oneHour(60),
  oneDay(1440);

  const AppointmentReminderLead(this.minutes);

  final int minutes;

  /// Valor guardado en otro momento (o editado a mano) que ya no corresponde a
  /// ninguna opción: se vuelve al valor por defecto.
  static AppointmentReminderLead fromMinutes(int? minutes) => values.firstWhere(
        (lead) => lead.minutes == minutes,
        orElse: () => AppointmentReminderLead.thirtyMinutes,
      );
}
