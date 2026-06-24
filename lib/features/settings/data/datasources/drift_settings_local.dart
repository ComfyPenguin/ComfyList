import '../../../../shared/data/local/app_database.dart';
import '../../../../shared/data/local/daos/settings_dao.dart';

/// Adaptador sobre [SettingsDao]. Mantiene la dependencia con Drift
/// confinada a `data/datasources/`.
class DriftSettingsLocal {
  DriftSettingsLocal(this._dao);

  final SettingsDao _dao;

  Future<SettingsRow> getOrCreate() => _dao.getOrCreate();
  Stream<SettingsRow> watch() => _dao.watch();
  Future<void> updateThemeMode(String mode) => _dao.updateThemeMode(mode);
  Future<void> updateNotificationsEnabled(bool enabled) =>
      _dao.updateNotificationsEnabled(enabled);

  Future<void> updateAppointmentsCompletionEnabled(bool enabled) =>
      _dao.updateAppointmentsCompletionEnabled(enabled);

  Future<void> updateCompletedToBottom(bool enabled) =>
      _dao.updateCompletedToBottom(enabled);

  Future<void> updateUse24HourFormat(bool enabled) =>
      _dao.updateUse24HourFormat(enabled);
}
