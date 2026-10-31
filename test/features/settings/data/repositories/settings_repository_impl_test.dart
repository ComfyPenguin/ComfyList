import 'package:comfy_list/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:comfy_list/features/settings/domain/entities/app_settings.dart';
import 'package:comfy_list/shared/data/local/app_database.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late SettingsRepositoryImpl repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = SettingsRepositoryImpl(db.settingsDao);
  });

  tearDown(() async {
    await db.close();
  });

  group('load', () {
    test('sin nada guardado devuelve los ajustes de fábrica', () async {
      final result = await repo.load();
      const defaults = AppSettings.defaults;

      expect(result.themeMode, defaults.themeMode);
      expect(result.notificationsEnabled, defaults.notificationsEnabled);
      expect(
        result.appointmentsCompletionEnabled,
        defaults.appointmentsCompletionEnabled,
      );
      expect(result.completedToBottom, defaults.completedToBottom);
      expect(
        result.appointmentsCompletedToBottom,
        defaults.appointmentsCompletedToBottom,
      );
      expect(result.appointmentsTodayOnTop, defaults.appointmentsTodayOnTop);
      expect(result.invertSwipeActions, defaults.invertSwipeActions);
      expect(result.use24HourFormat, defaults.use24HourFormat);
      expect(
        result.appointmentReminderMinutes,
        defaults.appointmentReminderMinutes,
      );
      expect(result.longPressHintSeen, defaults.longPressHintSeen);
      expect(result.trashRetentionDays, defaults.trashRetentionDays);
      expect(result.skippedUpdateBuild, noSkippedUpdateBuild);
      expect(result.lastUpdateCheckAt, isNull);
    });

    test('un plazo de papelera que el ajuste no ofrece cae al de fábrica',
        () async {
      await db.settingsDao.write(
        const SettingsTableCompanion(trashRetentionDays: Value(5)),
      );

      expect((await repo.load()).trashRetentionDays, defaultTrashRetentionDays);
    });

    test('un valor guardado sin márgenes deja la cita sin avisos', () async {
      await db.settingsDao.write(
        const SettingsTableCompanion(appointmentReminderMinutes: Value('')),
      );

      expect((await repo.load()).appointmentReminderMinutes, isEmpty);
    });

    test('lee la lista de márgenes guardada', () async {
      await db.settingsDao.write(
        const SettingsTableCompanion(appointmentReminderMinutes: Value('0,60')),
      );

      expect((await repo.load()).appointmentReminderMinutes, [0, 60]);
    });
  });

  group('cada ajuste se guarda y se lee de vuelta', () {
    final checkedAt = DateTime.utc(2026, 10, 12, 9);
    final cases = <String,
        (Future<void> Function(), Object? Function(AppSettings))>{
      'themeMode': (
        () => repo.setThemeMode(ThemeMode.dark),
        (s) => s.themeMode == ThemeMode.dark,
      ),
      'notificationsEnabled': (
        () => repo.setNotificationsEnabled(true),
        (s) => s.notificationsEnabled,
      ),
      'appointmentsCompletionEnabled': (
        () => repo.setAppointmentsCompletionEnabled(true),
        (s) => s.appointmentsCompletionEnabled,
      ),
      'completedToBottom': (
        () => repo.setCompletedToBottom(false),
        (s) => !s.completedToBottom,
      ),
      'appointmentsCompletedToBottom': (
        () => repo.setAppointmentsCompletedToBottom(false),
        (s) => !s.appointmentsCompletedToBottom,
      ),
      'appointmentsTodayOnTop': (
        () => repo.setAppointmentsTodayOnTop(false),
        (s) => !s.appointmentsTodayOnTop,
      ),
      'invertSwipeActions': (
        () => repo.setInvertSwipeActions(true),
        (s) => s.invertSwipeActions,
      ),
      'use24HourFormat': (
        () => repo.setUse24HourFormat(false),
        (s) => !s.use24HourFormat,
      ),
      'appointmentReminderMinutes': (
        () => repo.setAppointmentReminderMinutes(const [60, 0]),
        (s) => s.appointmentReminderMinutes.join(',') == '0,60',
      ),
      'longPressHintSeen': (
        () => repo.setLongPressHintSeen(true),
        (s) => s.longPressHintSeen,
      ),
      'trashRetentionDays': (
        () => repo.setTrashRetentionDays(15),
        (s) => s.trashRetentionDays == 15,
      ),
      'skippedUpdateBuild': (
        () => repo.setSkippedUpdateBuild(231),
        (s) => s.skippedUpdateBuild == 231,
      ),
      'lastUpdateCheckAt': (
        () => repo.setLastUpdateCheckAt(checkedAt),
        (s) => s.lastUpdateCheckAt?.isAtSameMomentAs(checkedAt) ?? false,
      ),
    };

    cases.forEach((name, spec) {
      test(name, () async {
        await spec.$1();

        expect(spec.$2(await repo.load()), isTrue);
      });
    });

    test('un ajuste no pisa a los demás', () async {
      await repo.setThemeMode(ThemeMode.dark);
      await repo.setTrashRetentionDays(7);

      final result = await repo.load();

      expect(result.themeMode, ThemeMode.dark);
      expect(result.trashRetentionDays, 7);
      expect(result.notificationsEnabled, AppSettings.defaults.notificationsEnabled);
    });

    test('los márgenes se guardan en su forma canónica', () async {
      await repo.setAppointmentReminderMinutes(const [1440, 30, 30]);

      expect((await repo.load()).appointmentReminderMinutes, [30, 1440]);
    });
  });

  group('watch', () {
    test('emite los ajustes tras cada cambio', () async {
      await repo.load();
      final emitted = <AppSettings>[];
      final sub = repo.watch().listen(emitted.add);
      await pumpEventQueue();

      await repo.setThemeMode(ThemeMode.dark);
      await pumpEventQueue();

      expect(emitted.last.themeMode, ThemeMode.dark);
      await sub.cancel();
    });
  });
}
