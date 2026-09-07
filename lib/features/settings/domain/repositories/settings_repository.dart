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

  Future<void> setInvertSwipeActions(bool enabled);

  Future<void> setUse24HourFormat(bool enabled);
}
