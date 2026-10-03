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

/// `settings_table` tal y como quedó en la v9, con el recordatorio ya en texto
/// y justo antes de la marca de la pista de pulsación larga.
const _v9SettingsTable = '''
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
  appointment_reminder_minutes TEXT NOT NULL DEFAULT '30',
  updated_at INTEGER NOT NULL,
  PRIMARY KEY (id)
);
''';

/// `settings_table` tal y como quedó en la v10: la última antes de que la
/// papelera supiera vaciarse sola. Es la foto de lo que hay en las
/// instalaciones que se van a migrar.
const _v10SettingsTable = '''
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
  appointment_reminder_minutes TEXT NOT NULL DEFAULT '30',
  long_press_hint_seen INTEGER NOT NULL DEFAULT 0,
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

  /// Deja la base de datos como una instalación de la v9: la tabla sin la
  /// columna de la pista y la fila guardada del usuario.
  Future<void> seedV9({
    String appointmentReminderMinutes = '30',
    String themeMode = 'dark',
  }) async {
    await db.settingsDao.getOrCreate();
    await db.customStatement('DROP TABLE settings_table');
    await db.customStatement(_v9SettingsTable);
    await db.customStatement(
      'INSERT INTO settings_table (id, theme_mode, appointment_reminder_minutes, '
      "updated_at) VALUES (1, '$themeMode', '$appointmentReminderMinutes', 0);",
    );
  }

  /// Deja la base de datos como una instalación de la v10: la tabla sin la
  /// columna del plazo de la papelera y la fila guardada del usuario.
  Future<void> seedV10({
    String themeMode = 'dark',
    String appointmentReminderMinutes = '30',
  }) async {
    await db.settingsDao.getOrCreate();
    await db.customStatement('DROP TABLE settings_table');
    await db.customStatement(_v10SettingsTable);
    await db.customStatement(
      'INSERT INTO settings_table (id, theme_mode, appointment_reminder_minutes, '
      "updated_at) VALUES (1, '$themeMode', '$appointmentReminderMinutes', 0);",
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

  group('migración de la v9 a la v10', () {
    test('añade la columna de la pista con valor por defecto', () async {
      await seedV9();

      await db.migration.onUpgrade(Migrator(db), 9, 10);

      final row = await db.settingsDao.getOrCreate();
      expect(row.longPressHintSeen, isFalse);

      // La columna debe existir de verdad en SQLite, no solo en el código.
      final columns = await db
          .customSelect('PRAGMA table_info(settings_table);')
          .get();
      expect(
        columns.any(
          (column) =>
              column.read<String>('name') == 'long_press_hint_seen',
        ),
        isTrue,
      );
    });

    test('conserva el resto de la fila', () async {
      await seedV9(appointmentReminderMinutes: '0,60', themeMode: 'light');

      await db.migration.onUpgrade(Migrator(db), 9, 10);

      final row = await db.settingsDao.getOrCreate();
      expect(row.themeMode, 'light');
      expect(row.appointmentReminderMinutes, '0,60');
      expect(row.id, 1);
    });

    test('la marca se puede escribir y watch emite el valor nuevo', () async {
      await seedV9();

      await db.migration.onUpgrade(Migrator(db), 9, 10);
      await db.settingsDao.updateLongPressHintSeen(true);

      final streamed = await db.settingsDao.watch().first;
      expect(streamed.longPressHintSeen, isTrue);
    });
  });

  group('migración de la v10 a la v11', () {
    test('añade el plazo de la papelera con el mes de fábrica', () async {
      await seedV10();

      await db.migration.onUpgrade(Migrator(db), 10, 11);

      final row = await db.settingsDao.getOrCreate();
      expect(row.trashRetentionDays, 30);

      // La columna debe existir de verdad en SQLite, no solo en el código.
      final columns = await db
          .customSelect('PRAGMA table_info(settings_table);')
          .get();
      expect(
        columns.any(
          (column) => column.read<String>('name') == 'trash_retention_days',
        ),
        isTrue,
      );
    });

    test('conserva el resto de la fila', () async {
      await seedV10(themeMode: 'light', appointmentReminderMinutes: '0,60');

      await db.migration.onUpgrade(Migrator(db), 10, 11);

      final row = await db.settingsDao.getOrCreate();
      expect(row.themeMode, 'light');
      expect(row.appointmentReminderMinutes, '0,60');
      expect(row.id, 1);
    });

    test('el plazo se puede escribir y watch emite el valor nuevo', () async {
      await seedV10();

      await db.migration.onUpgrade(Migrator(db), 10, 11);
      await db.settingsDao.updateTrashRetentionDays(30);

      final streamed = await db.settingsDao.watch().first;
      expect(streamed.trashRetentionDays, 30);
    });
  });

  group('migración de la v11 a la v12', () {
    /// Deja la fila como la dejaba la v11: con «nunca» de fábrica.
    Future<void> seedV11() async {
      await db.settingsDao.getOrCreate();
      await db.customStatement(
        'UPDATE settings_table SET trash_retention_days = 0 WHERE id = 1',
      );
    }

    test('un plazo que nadie eligió pasa al mes de fábrica', () async {
      await seedV11();

      await db.migration.onUpgrade(Migrator(db), 11, 12);

      final row = await db.settingsDao.getOrCreate();
      expect(row.trashRetentionDays, 30);
    });

    test('un plazo ya elegido se respeta', () async {
      await seedV11();
      await db.settingsDao.updateTrashRetentionDays(7);

      await db.migration.onUpgrade(Migrator(db), 11, 12);

      final row = await db.settingsDao.getOrCreate();
      expect(row.trashRetentionDays, 7);
    });
  });

  group('migración de la v12 a la v13', () {
    /// Deja la base como una instalación de la v12, sin la tabla de pendientes.
    Future<void> seedV12() async {
      await db.settingsDao.getOrCreate();
      await db.customStatement('DROP TABLE trash_pending_table');
    }

    test('crea la tabla donde se apuntan los pendientes', () async {
      await seedV12();

      await db.migration.onUpgrade(Migrator(db), 12, 13);

      final columns = await db
          .customSelect('PRAGMA table_info(trash_pending_table);')
          .get();
      final names = [for (final column in columns) column.read<String>('name')];
      expect(names, containsAll(['uid', 'doc_id', 'created_at']));
    });

    test('los pendientes se pueden apuntar, podar y quitar', () async {
      await seedV12();

      await db.migration.onUpgrade(Migrator(db), 12, 13);
      await db.trashPendingDao.add(uid: 'u1', docId: 'd1');
      await db.trashPendingDao.add(uid: 'u1', docId: 'd2');
      await db.trashPendingDao.add(uid: 'u2', docId: 'd3');

      expect(await db.trashPendingDao.idsOf('u1'), containsAll(['d1', 'd2']));
      expect(await db.trashPendingDao.idsOf('u2'), ['d3']);

      await db.trashPendingDao.keepOnly(uid: 'u1', ids: {'d1'});
      expect(await db.trashPendingDao.idsOf('u1'), ['d1']);
      expect(await db.trashPendingDao.idsOf('u2'), ['d3']);

      await db.trashPendingDao.remove(uid: 'u1', docId: 'd1');
      expect(await db.trashPendingDao.idsOf('u1'), isEmpty);
    });

    test('conserva los ajustes guardados', () async {
      await seedV12();
      await db.settingsDao.updateTrashRetentionDays(7);

      await db.migration.onUpgrade(Migrator(db), 12, 13);

      final row = await db.settingsDao.getOrCreate();
      expect(row.trashRetentionDays, 7);
    });
  });
}
