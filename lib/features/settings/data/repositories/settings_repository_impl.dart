import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';

import '../../../../shared/data/local/app_database.dart';
import '../../../../shared/data/local/daos/settings_dao.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._dao);

  final SettingsDao _dao;

  @override
  Future<AppSettings> load() async => _fromRow(await _dao.getOrCreate());

  @override
  Stream<AppSettings> watch() => _dao.watch().map(_fromRow);

  @override
  Future<void> setThemeMode(ThemeMode mode) => _dao.write(
        SettingsTableCompanion(
          themeMode: Value(AppSettings.themeModeToString(mode)),
        ),
      );

  @override
  Future<void> setNotificationsEnabled(bool enabled) => _dao.write(
        SettingsTableCompanion(notificationsEnabled: Value(enabled)),
      );

  @override
  Future<void> setCompletedToBottom(bool enabled) => _dao.write(
        SettingsTableCompanion(completedToBottom: Value(enabled)),
      );

  @override
  Future<void> setAppointmentsCompletedToBottom(bool enabled) => _dao.write(
        SettingsTableCompanion(appointmentsCompletedToBottom: Value(enabled)),
      );

  @override
  Future<void> setAppointmentsTodayOnTop(bool enabled) => _dao.write(
        SettingsTableCompanion(appointmentsTodayOnTop: Value(enabled)),
      );

  @override
  Future<void> setInvertSwipeActions(bool enabled) => _dao.write(
        SettingsTableCompanion(invertSwipeActions: Value(enabled)),
      );

  @override
  Future<void> setUse24HourFormat(bool enabled) => _dao.write(
        SettingsTableCompanion(use24HourFormat: Value(enabled)),
      );

  @override
  Future<void> setLongPressHintSeen(bool seen) => _dao.write(
        SettingsTableCompanion(longPressHintSeen: Value(seen)),
      );

  @override
  Future<void> setTrashRetentionDays(int days) => _dao.write(
        SettingsTableCompanion(trashRetentionDays: Value(days)),
      );

  @override
  Future<void> setSkippedUpdateBuild(int build) => _dao.write(
        SettingsTableCompanion(skippedUpdateBuild: Value(build)),
      );

  @override
  Future<void> setLastUpdateCheckAt(DateTime at) => _dao.write(
        SettingsTableCompanion(lastUpdateCheckAt: Value(at.toUtc())),
      );

  AppSettings _fromRow(SettingsRow row) => AppSettings(
        themeMode: AppSettings.parseThemeMode(row.themeMode),
        notificationsEnabled: row.notificationsEnabled,
        completedToBottom: row.completedToBottom,
        appointmentsCompletedToBottom: row.appointmentsCompletedToBottom,
        appointmentsTodayOnTop: row.appointmentsTodayOnTop,
        invertSwipeActions: row.invertSwipeActions,
        use24HourFormat: row.use24HourFormat,
        longPressHintSeen: row.longPressHintSeen,
        trashRetentionDays: AppSettings.parseTrashRetentionDays(
          row.trashRetentionDays,
        ),
        skippedUpdateBuild: row.skippedUpdateBuild,
        lastUpdateCheckAt: row.lastUpdateCheckAt,
      );
}
