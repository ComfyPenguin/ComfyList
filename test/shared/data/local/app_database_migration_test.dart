import 'package:comfy_list/features/settings/domain/entities/app_settings.dart';
import 'package:comfy_list/shared/data/local/app_database.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// `settings_table` tal y como quedó en la v8, la última antes de que el
/// recordatorio pasara a ser una lista. Escrito a mano a propósito: es la foto
/// de lo que hay en las instalaciones que se van a migrar.
const _v8SettingsTable = '''
CREATE TABLE settings_table (
  id INTEGER NOT NULL DEFAULT 1,
  theme_mode TEXT NOT NULL DEFAULT 'system',
  notifications_enabled INTEGER NOT NULL DEFAULT 0,
  appointments_completion_enabled INTEGER NOT NULL DEFAULT 0,
  completed_to_bottom INTEGER NOT NULL DEFAULT 1,
  appointments_completed_to_bottom INTEGER NOT NULL DEFAULT 1,
  appointments_today_on_top INTEGER NOT NULL DEFAULT 1,
  invert_swipe_actions INTEGER NOT NULL DEFAULT 0,
  use24_hour_format INTEGER NOT NULL DEFAULT 1,
  appointment_reminder_minutes INTEGER NOT NULL DEFAULT 30,
  updated_at INTEGER NOT NULL,
  PRIMARY KEY (id)
);
''';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  /// Deja la base de datos como una instalación de la v8: la tabla con el
  /// recordatorio entero y la fila guardada del usuario.
  Future<void> seedV8({
    required int reminderMinutes,
    String themeMode = 'dark',
  }) async {
    // La primera lectura crea el esquema; luego se sustituye por el de la v8.
    await db.settingsDao.getOrCreate();
    await db.customStatement('DROP TABLE settings_table');
    await db.customStatement(_v8SettingsTable);
    await db.customStatement(
      "INSERT INTO settings_table (id, theme_mode, appointment_reminder_minutes, "
      "updated_at) VALUES (1, '$themeMode', $reminderMinutes, 0);",
    );
  }

  /// Definición real de la columna en la base de datos. `PRAGMA table_info` es
  /// lo que dice SQLite, no lo que la app cree: sin la migración el tipo sigue
  /// siendo INTEGER aunque el código lo lea como texto.
  Future<QueryRow> reminderColumn() async {
    final columns = await db
        .customSelect('PRAGMA table_info(settings_table);')
        .get();
    return columns.firstWhere(
      (row) => row.read<String>('name') == 'appointment_reminder_minutes',
    );
  }

  group('migración de la v8 a la v9', () {
    test('la columna del recordatorio queda declarada como texto', () async {
      await seedV8(reminderMinutes: 30);
      final before = await reminderColumn();
      expect(before.read<String>('type'), 'INTEGER');

      await db.migration.onUpgrade(Migrator(db), 8, 9);

      final after = await reminderColumn();
      expect(after.read<String>('type'), 'TEXT');
      expect(after.read<String?>('dflt_value'), "'30'");
    });

    test('el recordatorio guardado pasa a ser el único de la lista', () async {
      await seedV8(reminderMinutes: 1440);

      await db.migration.onUpgrade(Migrator(db), 8, 9);

      final row = await db.settingsDao.getOrCreate();
      expect(row.appointmentReminderMinutes, '1440');
      expect(AppSettings.parseReminderMinutes(row.appointmentReminderMinutes), [
        1440,
      ]);
    });

    test('el resto de la fila se copia tal cual', () async {
      await seedV8(reminderMinutes: 60, themeMode: 'light');

      await db.migration.onUpgrade(Migrator(db), 8, 9);

      final row = await db.settingsDao.getOrCreate();
      expect(row.themeMode, 'light');
      expect(row.id, 1);
    });

    test('la fila sigue siendo la única y se puede escribir en ella', () async {
      await seedV8(reminderMinutes: 30);

      await db.migration.onUpgrade(Migrator(db), 8, 9);
      await db.settingsDao.updateAppointmentReminderMinutes('0,30');

      final count = await db.managers.settingsTable.count();
      expect(count, 1);
      final streamed = await db.settingsDao.watch().first;
      expect(streamed.appointmentReminderMinutes, '0,30');
    });
  });
}
