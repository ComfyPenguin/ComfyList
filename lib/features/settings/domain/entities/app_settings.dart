import 'package:flutter/material.dart';

/// Días que ofrece el ajuste de la papelera antes de vaciarla sola. `0` es
/// «nunca»: los borrados se quedan hasta que el usuario la vacíe a mano.
const List<int> trashRetentionDayOptions = [0, 7, 15, 30];

/// Días que aguanta la papelera de fábrica: un mes de margen antes de empezar a
/// vaciarse sola.
const int defaultTrashRetentionDays = 30;

/// Valor de [AppSettings.skippedUpdateBuild] cuando no se ha descartado ninguna
/// versión.
const int noSkippedUpdateBuild = 0;

/// Configuración local de la app (tema y preferencias de usuario).
@immutable
class AppSettings {
  const AppSettings({
    required this.themeMode,
    required this.notificationsEnabled,
    required this.completedToBottom,
    required this.appointmentsCompletedToBottom,
    required this.appointmentsTodayOnTop,
    required this.invertSwipeActions,
    required this.use24HourFormat,
    required this.longPressHintSeen,
    required this.trashRetentionDays,
    required this.skippedUpdateBuild,
    required this.lastUpdateCheckAt,
  });

  final ThemeMode themeMode;

  /// Avisos de citas. Apagado de fábrica, como en `SettingsTable`: el permiso
  /// del sistema se pide al encenderlo.
  final bool notificationsEnabled;

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

  /// Si `true`, ya se mostró la pista de mantener pulsada una tarjeta para
  /// editarla. Se muestra una única vez.
  final bool longPressHintSeen;

  /// Días que aguanta un borrado en la papelera antes de que la app la vacíe
  /// sola: uno de [trashRetentionDayOptions], con `0` para «nunca». De fábrica
  /// [defaultTrashRetentionDays].
  final int trashRetentionDays;

  /// Nº de build que se descartó con «Ahora no» ([noSkippedUpdateBuild] si
  /// ninguna): esa versión ya no vuelve a preguntar.
  final int skippedUpdateBuild;

  /// Cuándo se consultó por última vez si hay versión nueva. `null` es «nunca»:
  /// el comprobador arranca con el primer ajuste leído.
  final DateTime? lastUpdateCheckAt;

  /// Si la papelera se vacía sola ([trashRetentionDays] distinto de «nunca»).
  bool get emptiesTrashItself => trashRetentionDays > 0;

  static const AppSettings defaults = AppSettings(
    themeMode: ThemeMode.system,
    notificationsEnabled: false,
    completedToBottom: true,
    appointmentsCompletedToBottom: true,
    appointmentsTodayOnTop: true,
    invertSwipeActions: false,
    use24HourFormat: true,
    longPressHintSeen: false,
    trashRetentionDays: defaultTrashRetentionDays,
    skippedUpdateBuild: noSkippedUpdateBuild,
    lastUpdateCheckAt: null,
  );

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? notificationsEnabled,
    bool? completedToBottom,
    bool? appointmentsCompletedToBottom,
    bool? appointmentsTodayOnTop,
    bool? invertSwipeActions,
    bool? use24HourFormat,
    bool? longPressHintSeen,
    int? trashRetentionDays,
    int? skippedUpdateBuild,
    DateTime? lastUpdateCheckAt,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      completedToBottom: completedToBottom ?? this.completedToBottom,
      appointmentsCompletedToBottom:
          appointmentsCompletedToBottom ?? this.appointmentsCompletedToBottom,
      appointmentsTodayOnTop:
          appointmentsTodayOnTop ?? this.appointmentsTodayOnTop,
      invertSwipeActions: invertSwipeActions ?? this.invertSwipeActions,
      use24HourFormat: use24HourFormat ?? this.use24HourFormat,
      longPressHintSeen: longPressHintSeen ?? this.longPressHintSeen,
      trashRetentionDays: trashRetentionDays ?? this.trashRetentionDays,
      skippedUpdateBuild: skippedUpdateBuild ?? this.skippedUpdateBuild,
      lastUpdateCheckAt: lastUpdateCheckAt ?? this.lastUpdateCheckAt,
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

  /// Un valor guardado que el ajuste no ofrece —otra versión de la app, una
  /// fila tocada a mano— cae a «nunca», para que el control tenga siempre una
  /// opción que marcar.
  static int parseTrashRetentionDays(int value) =>
      trashRetentionDayOptions.contains(value) ? value : defaultTrashRetentionDays;
}
