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
      expect(row.notificationsEnabled, isTrue);
      expect(row.appointmentsCompletionEnabled, isFalse);
      expect(row.completedToBottom, isTrue);
      expect(row.appointmentsCompletedToBottom, isTrue);
      expect(row.invertSwipeActions, isFalse);
      expect(row.use24HourFormat, isTrue);
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
