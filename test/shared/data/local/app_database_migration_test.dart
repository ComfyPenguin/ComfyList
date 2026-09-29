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
    test('crea la tabla de la papelera y no toca los ajustes', () async {
      await db.settingsDao.getOrCreate();
      await db.settingsDao.updateThemeMode('light');
      // Una instalación de la v10 todavía no tiene la papelera.
      await db.customStatement('DROP TABLE trash_table');

      await db.migration.onUpgrade(Migrator(db), 10, 11);

      // La tabla existe de verdad en SQLite y acepta filas.
      await db.trashDao.insertAll([
        TrashTableCompanion.insert(
          uid: 'u1',
          groupId: 'g1',
          kind: 'todo',
          itemId: 't1',
          parentId: const Value('L1'),
          label: 'Comprar pan',
          payload: '{"id":"t1"}',
          deletedAt: DateTime.now().toUtc(),
        ),
      ]);
      final rows = await db.trashDao.listByUid('u1');
      expect(rows, hasLength(1));
      expect(rows.single.parentId, 'L1');

      final settings = await db.settingsDao.getOrCreate();
      expect(settings.themeMode, 'light');
      expect(settings.id, 1);
    });
  });
}
