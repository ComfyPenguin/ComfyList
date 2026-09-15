import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'daos/account_cache_dao.dart';
import 'daos/settings_dao.dart';
import 'tables/account_cache_table.dart';
import 'tables/settings_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [SettingsTable, AccountCacheTable],
  daos: [SettingsDao, AccountCacheDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'comfy_list'));

  // Constructor para tests con conexión inyectada (ej. NativeDatabase.memory()).
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (migrator, from, to) async {
          if (from < 2) {
            await migrator.addColumn(
              settingsTable,
              settingsTable.appointmentsCompletionEnabled,
            );
          }
          if (from < 3) {
            await migrator.addColumn(
              settingsTable,
              settingsTable.completedToBottom,
            );
          }
          if (from < 4) {
            await migrator.addColumn(
              settingsTable,
              settingsTable.use24HourFormat,
            );
          }
          if (from < 5) {
            await migrator.addColumn(
              settingsTable,
              settingsTable.appointmentsCompletedToBottom,
            );
          }
          if (from < 6) {
            await migrator.addColumn(
              settingsTable,
              settingsTable.invertSwipeActions,
            );
          }
          if (from < 7) {
            await migrator.addColumn(
              settingsTable,
              settingsTable.appointmentsTodayOnTop,
            );
          }
          if (from < 8) {
            await migrator.addColumn(
              settingsTable,
              settingsTable.appointmentReminderMinutes,
            );
          }
        },
      );
}
