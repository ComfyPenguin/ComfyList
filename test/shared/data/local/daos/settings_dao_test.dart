import 'package:comfy_list/shared/data/local/app_database.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('SettingsDao.getOrCreate', () {
    test('inserta defaults en la primera llamada', () async {
      final dao = db.settingsDao;
      final row = await dao.getOrCreate();

      expect(row.id, 1);
      expect(row.themeMode, 'system');
      expect(row.notificationsEnabled, isFalse);
      expect(row.completedToBottom, isTrue);
      expect(row.appointmentsCompletedToBottom, isTrue);
      expect(row.appointmentsTodayOnTop, isTrue);
      expect(row.invertSwipeActions, isFalse);
      expect(row.use24HourFormat, isTrue);
      expect(row.longPressHintSeen, isFalse);
      expect(row.trashRetentionDays, 30);
    });

    test('devuelve la misma fila en llamadas sucesivas y deja una sola row',
        () async {
      final dao = db.settingsDao;
      await dao.getOrCreate();
      final second = await dao.getOrCreate();

      expect(second.id, 1);
      expect(second.themeMode, 'system');

      final count = await db.managers.settingsTable.count();
      expect(count, 1, reason: 'La tabla singleton no debe tener duplicados.');
    });
  });

  group('SettingsDao.write', () {
    test('guarda las columnas indicadas y watch emite el valor nuevo', () async {
      final dao = db.settingsDao;
      await dao.getOrCreate();

      await dao.write(
        const SettingsTableCompanion(
          use24HourFormat: Value(false),
          trashRetentionDays: Value(15),
        ),
      );

      final streamed = await dao.watch().first;
      expect(streamed.use24HourFormat, isFalse);
      expect(streamed.trashRetentionDays, 15);
    });

    test('crea la fila si todavía no existe', () async {
      final dao = db.settingsDao;

      await dao.write(const SettingsTableCompanion(longPressHintSeen: Value(true)));

      final row = await dao.getOrCreate();
      expect(row.longPressHintSeen, isTrue);
      expect(await db.managers.settingsTable.count(), 1);
    });

    test('deja intactas las columnas que no se tocan', () async {
      final dao = db.settingsDao;
      await dao.getOrCreate();

      await dao.write(const SettingsTableCompanion(themeMode: Value('dark')));

      final row = await dao.getOrCreate();
      expect(row.themeMode, 'dark');
      expect(row.use24HourFormat, isTrue);
      expect(row.trashRetentionDays, 30);
    });

    test('pone updatedAt al escribir', () async {
      final dao = db.settingsDao;
      // Drift guarda las fechas con precisión de segundo: se parte de una
      // fila antigua para que el avance se vea.
      await db.into(db.settingsTable).insert(
            SettingsTableCompanion.insert(updatedAt: DateTime.utc(2020)),
          );

      await dao.write(const SettingsTableCompanion(themeMode: Value('dark')));

      final streamed = await dao.watch().first;
      expect(streamed.updatedAt.isAfter(DateTime.utc(2020)), isTrue);
    });
  });
}
