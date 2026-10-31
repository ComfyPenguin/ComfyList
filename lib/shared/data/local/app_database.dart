import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'daos/account_cache_dao.dart';
import 'daos/settings_dao.dart';
import 'daos/trash_pending_dao.dart';
import 'tables/account_cache_table.dart';
import 'tables/settings_table.dart';
import 'tables/trash_pending_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [SettingsTable, AccountCacheTable, TrashPendingTable],
  daos: [SettingsDao, AccountCacheDao, TrashPendingDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'comfy_list'));

  // Constructor para tests con conexión inyectada (ej. NativeDatabase.memory()).
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 16;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (migrator, from, to) async {
          // La v2 añadía `appointments_completion_enabled`, que la v15 elimina:
          // quien viene de la v1 no necesita una columna que se borra al final.
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
          // La v8 añadía `appointment_reminder_minutes`, que la v16 elimina: lo
          // que se guarda de ese ajuste ya no se lee, así que no se migra.
          if (from < 9) {
            // La v9 recreaba la tabla para cambiar el tipo de esa columna. Ahora
            // la recreación (que usa el esquema actual) ya la deja fuera; se
            // mantiene porque es la que trae las columnas posteriores.
            //
            // La recreación usa el esquema actual, así que las columnas que
            // llegaron después de la v9 no existen en la tabla antigua: hay
            // que declararlas en `newColumns` para que la copia no las busque
            // (se quedan con su valor por defecto).
            await migrator.alterTable(
              TableMigration(
                settingsTable,
                newColumns: [
                  settingsTable.longPressHintSeen,
                  settingsTable.trashRetentionDays,
                  settingsTable.skippedUpdateBuild,
                  settingsTable.lastUpdateCheckAt,
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
          if (from < 12) {
            // La v11 nació con «nunca» por defecto, antes de que la papelera
            // arrancara con un mes de plazo: ese 0 no lo había elegido nadie.
            await customStatement(
              'UPDATE settings_table SET trash_retention_days = 30 '
              'WHERE trash_retention_days = 0',
            );
          }
          if (from < 13) {
            await migrator.createTable(trashPendingTable);
          }
          // Quien viene de la v8 o antes ya recibe las columnas con la
          // recreación de la tabla de la v9; solo de la v9 en adelante llegan
          // sin ellas.
          if (from >= 9 && from < 14) {
            await migrator.addColumn(
              settingsTable,
              settingsTable.skippedUpdateBuild,
            );
            await migrator.addColumn(
              settingsTable,
              settingsTable.lastUpdateCheckAt,
            );
          }
          if (from < 16) {
            // Completar citas (v15) y los márgenes de recordatorio globales
            // (v16) dejan de ser ajustes: sus columnas sobran. Quitarlas obliga
            // a recrear la tabla con el esquema actual, y una sola recreación
            // se lleva las dos; todas las demás columnas existen ya en este
            // punto (las pasadas por la recreación de la v9 y los `addColumn`
            // de arriba), así que no hay `newColumns`.
            await migrator.alterTable(TableMigration(settingsTable));
          }
        },
      );
}
