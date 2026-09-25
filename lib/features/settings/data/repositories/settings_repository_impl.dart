import 'package:flutter/material.dart';

import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/drift_settings_local.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._local);

  final DriftSettingsLocal _local;

  @override
  Future<AppSettings> load() async {
    final row = await _local.getOrCreate();
    return AppSettings(
      themeMode: AppSettings.parseThemeMode(row.themeMode),
      notificationsEnabled: row.notificationsEnabled,
      appointmentsCompletionEnabled: row.appointmentsCompletionEnabled,
      completedToBottom: row.completedToBottom,
      appointmentsCompletedToBottom: row.appointmentsCompletedToBottom,
      appointmentsTodayOnTop: row.appointmentsTodayOnTop,
      invertSwipeActions: row.invertSwipeActions,
      use24HourFormat: row.use24HourFormat,
      appointmentReminderMinutes: AppSettings.parseReminderMinutes(
        row.appointmentReminderMinutes,
      ),
      longPressHintSeen: row.longPressHintSeen,
    );
  }

  @override
  Stream<AppSettings> watch() {
    return _local.watch().map(
          (row) => AppSettings(
            themeMode: AppSettings.parseThemeMode(row.themeMode),
            notificationsEnabled: row.notificationsEnabled,
            appointmentsCompletionEnabled: row.appointmentsCompletionEnabled,
            completedToBottom: row.completedToBottom,
            appointmentsCompletedToBottom: row.appointmentsCompletedToBottom,
            appointmentsTodayOnTop: row.appointmentsTodayOnTop,
            invertSwipeActions: row.invertSwipeActions,
            use24HourFormat: row.use24HourFormat,
            appointmentReminderMinutes: AppSettings.parseReminderMinutes(
              row.appointmentReminderMinutes,
            ),
            longPressHintSeen: row.longPressHintSeen,
          ),
        );
  }

  @override
  Future<void> setThemeMode(ThemeMode mode) {
    return _local.updateThemeMode(AppSettings.themeModeToString(mode));
  }

  @override
  Future<void> setNotificationsEnabled(bool enabled) {
    return _local.updateNotificationsEnabled(enabled);
  }

  @override
  Future<void> setAppointmentsCompletionEnabled(bool enabled) {
    return _local.updateAppointmentsCompletionEnabled(enabled);
  }

  @override
  Future<void> setCompletedToBottom(bool enabled) {
    return _local.updateCompletedToBottom(enabled);
  }

  @override
  Future<void> setAppointmentsCompletedToBottom(bool enabled) {
    return _local.updateAppointmentsCompletedToBottom(enabled);
  }

  @override
  Future<void> setAppointmentsTodayOnTop(bool enabled) {
    return _local.updateAppointmentsTodayOnTop(enabled);
  }

  @override
  Future<void> setInvertSwipeActions(bool enabled) {
    return _local.updateInvertSwipeActions(enabled);
  }

  @override
  Future<void> setUse24HourFormat(bool enabled) {
    return _local.updateUse24HourFormat(enabled);
  }

  @override
  Future<void> setAppointmentReminderMinutes(List<int> minutes) {
    return _local.updateAppointmentReminderMinutes(
      AppSettings.reminderMinutesToString(minutes),
    );
  }

  @override
  Future<void> setLongPressHintSeen(bool seen) {
    return _local.updateLongPressHintSeen(seen);
  }
}
