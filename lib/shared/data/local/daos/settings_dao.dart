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

  /// Escribe [values] en la fila singleton, creándola antes si no existe, y
  /// pone `updatedAt`. Cada ajuste pasa por aquí con solo su columna.
  Future<void> write(SettingsTableCompanion values) async {
    await getOrCreate();
    await (update(settingsTable)..where((t) => t.id.equals(1))).write(
      values.copyWith(updatedAt: Value(DateTime.now().toUtc())),
    );
  }
}
