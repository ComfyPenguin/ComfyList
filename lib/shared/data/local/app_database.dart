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
  int get schemaVersion => 11;

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
          if (from < 9) {
            // El recordatorio pasa de uno a tres, así que la columna deja de ser
            // un entero y guarda la lista separada por comas. Cambiar el tipo
            // obliga a recrear la tabla, y el margen que hubiera se conserva
            // como el único de la lista.
            //
            // La recreación usa el esquema actual, así que las columnas que
            // llegaron después de la v9 no existen en la tabla antigua: hay
            // que declararlas en `newColumns` para que la copia no las busque
            // (se quedan con su valor por defecto).
            await migrator.alterTable(
              TableMigration(
                settingsTable,
                columnTransformer: {
                  settingsTable.appointmentReminderMinutes:
                      settingsTable.appointmentReminderMinutes.cast<String>(),
                },
                newColumns: [
                  settingsTable.longPressHintSeen,
                  settingsTable.trashRetentionDays,
                ],
              ),
            );
          }
          if (from == 9) {
            // Solo la v9 necesita añadir la columna a mano: quien viene de
            // antes ya la recibe con la recreación de la tabla de arriba.
            await migrator.addColumn(
              settingsTable,
              settingsTable.longPressHintSeen,
            );
          }
          // Quien viene de la v8 o antes ya recibe la columna con la
          // recreación de la tabla de arriba; solo la v9 y la v10 llegan aquí
          // sin ella.
          if (from >= 9 && from < 11) {
            await migrator.addColumn(
              settingsTable,
              settingsTable.trashRetentionDays,
            );
          }
        },
      );
}
