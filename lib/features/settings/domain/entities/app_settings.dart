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

  static const AppSettings defaults = AppSettings(
    themeMode: ThemeMode.system,
    notificationsEnabled: true,
    appointmentsCompletionEnabled: false,
    completedToBottom: true,
    appointmentsCompletedToBottom: true,
    appointmentsTodayOnTop: true,
    invertSwipeActions: false,
    use24HourFormat: true,
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
