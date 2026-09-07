import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/settings_table.dart';

part 'settings_dao.g.dart';

@DriftAccessor(tables: [SettingsTable])
class SettingsDao extends DatabaseAccessor<AppDatabase> with _$SettingsDaoMixin {
  SettingsDao(super.db);

  /// Obtiene la fila singleton (la crea con defaults si no existe).
  Future<SettingsRow> getOrCreate() async {
    final existing = await (select(settingsTable)
          ..where((t) => t.id.equals(1))
          ..limit(1))
        .getSingleOrNull();
    if (existing != null) return existing;

    await into(settingsTable).insert(
      SettingsTableCompanion.insert(
        updatedAt: DateTime.now().toUtc(),
      ),
    );
    return (select(settingsTable)..where((t) => t.id.equals(1))).getSingle();
  }

  /// Stream de la única fila — lanza si todavía no se creó (llama a [getOrCreate] al boot).
  Stream<SettingsRow> watch() {
    return (select(settingsTable)..where((t) => t.id.equals(1)))
        .watchSingle();
  }

  Future<void> updateThemeMode(String mode) async {
    await getOrCreate();
    await (update(settingsTable)..where((t) => t.id.equals(1))).write(
      SettingsTableCompanion(
        themeMode: Value(mode),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  Future<void> updateNotificationsEnabled(bool enabled) async {
    await getOrCreate();
    await (update(settingsTable)..where((t) => t.id.equals(1))).write(
      SettingsTableCompanion(
        notificationsEnabled: Value(enabled),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  Future<void> updateAppointmentsCompletionEnabled(bool enabled) async {
    await getOrCreate();
    await (update(settingsTable)..where((t) => t.id.equals(1))).write(
      SettingsTableCompanion(
        appointmentsCompletionEnabled: Value(enabled),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  Future<void> updateCompletedToBottom(bool enabled) async {
    await getOrCreate();
    await (update(settingsTable)..where((t) => t.id.equals(1))).write(
      SettingsTableCompanion(
        completedToBottom: Value(enabled),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  Future<void> updateAppointmentsCompletedToBottom(bool enabled) async {
    await getOrCreate();
    await (update(settingsTable)..where((t) => t.id.equals(1))).write(
      SettingsTableCompanion(
        appointmentsCompletedToBottom: Value(enabled),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  Future<void> updateInvertSwipeActions(bool enabled) async {
    await getOrCreate();
    await (update(settingsTable)..where((t) => t.id.equals(1))).write(
      SettingsTableCompanion(
        invertSwipeActions: Value(enabled),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  Future<void> updateUse24HourFormat(bool enabled) async {
    await getOrCreate();
    await (update(settingsTable)..where((t) => t.id.equals(1))).write(
      SettingsTableCompanion(
        use24HourFormat: Value(enabled),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }
}
