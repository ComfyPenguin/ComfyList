import 'package:comfy_list/shared/data/local/app_database.dart';
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
      expect(row.appointmentsCompletionEnabled, isFalse);
      expect(row.completedToBottom, isTrue);
      expect(row.appointmentsCompletedToBottom, isTrue);
      expect(row.appointmentsTodayOnTop, isTrue);
      expect(row.invertSwipeActions, isFalse);
      expect(row.use24HourFormat, isTrue);
      expect(row.appointmentReminderMinutes, '30');
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

  group('SettingsDao.updateAppointmentReminderMinutes', () {
    test('persiste la lista de márgenes y watch emite el valor nuevo', () async {
      final dao = db.settingsDao;
      await dao.getOrCreate();

      await dao.updateAppointmentReminderMinutes('0,30,1440');

      final streamed = await dao.watch().first;
      expect(streamed.appointmentReminderMinutes, '0,30,1440');
    });
  });

  group('SettingsDao.updateLongPressHintSeen', () {
    test('persiste la marca y watch emite el valor nuevo', () async {
      final dao = db.settingsDao;
      await dao.getOrCreate();

      await dao.updateLongPressHintSeen(true);

      final streamed = await dao.watch().first;
      expect(streamed.longPressHintSeen, isTrue);
    });
  });

  group('SettingsDao.updateTrashRetentionDays', () {
    test('persiste el plazo y watch emite el valor nuevo', () async {
      final dao = db.settingsDao;
      await dao.getOrCreate();

      await dao.updateTrashRetentionDays(15);

      final streamed = await dao.watch().first;
      expect(streamed.trashRetentionDays, 15);
    });
  });

  group('SettingsDao.updateThemeMode', () {
    test('persiste el cambio y watch emite con updatedAt mayor', () async {
      final dao = db.settingsDao;
      final initial = await dao.getOrCreate();

      await dao.updateThemeMode('dark');

      final streamed = await dao.watch().first;
      expect(streamed.themeMode, 'dark');
      expect(
        streamed.updatedAt.isAfter(initial.updatedAt) ||
            streamed.updatedAt.isAtSameMomentAs(initial.updatedAt),
        isTrue,
        reason: 'updatedAt debe avanzar o mantenerse al persistir.',
      );
    });
  });
}
