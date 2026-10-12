import 'package:flutter/material.dart';

import '../entities/app_settings.dart';

/// Contrato del repositorio de settings — la implementación vive en `data/`.
abstract class SettingsRepository {
  /// Obtiene los settings actuales (creando defaults si no existen).
  Future<AppSettings> load();

  /// Stream reactivo a cambios de la fila singleton de settings.
  Stream<AppSettings> watch();

  Future<void> setThemeMode(ThemeMode mode);

  Future<void> setNotificationsEnabled(bool enabled);

  Future<void> setAppointmentsCompletionEnabled(bool enabled);

  Future<void> setCompletedToBottom(bool enabled);

  Future<void> setAppointmentsCompletedToBottom(bool enabled);

  Future<void> setAppointmentsTodayOnTop(bool enabled);

  Future<void> setInvertSwipeActions(bool enabled);

  Future<void> setUse24HourFormat(bool enabled);

  Future<void> setAppointmentReminderMinutes(List<int> minutes);

  /// Marca que ya se mostró la pista de mantener pulsada una tarjeta para
  /// editarla, para que no vuelva a aparecer.
  Future<void> setLongPressHintSeen(bool seen);

  /// Días que aguanta un borrado en la papelera antes de vaciarla sola; `0` es
  /// «nunca».
  Future<void> setTrashRetentionDays(int days);

  /// Nº de build descartado con «Ahora no» ([noSkippedUpdateBuild] si ninguno).
  Future<void> setSkippedUpdateBuild(int build);

  /// Marca cuándo se comprobó por última vez si hay versión nueva.
  Future<void> setLastUpdateCheckAt(DateTime at);
}
