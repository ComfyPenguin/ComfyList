import 'dart:async';

import 'package:comfy_list/features/settings/data/datasources/drift_settings_local.dart';
import 'package:comfy_list/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:comfy_list/features/settings/domain/entities/app_settings.dart';
import 'package:comfy_list/shared/data/local/app_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDriftSettingsLocal extends Mock implements DriftSettingsLocal {}

void main() {
  late _MockDriftSettingsLocal local;
  late SettingsRepositoryImpl repo;

  setUp(() {
    local = _MockDriftSettingsLocal();
    repo = SettingsRepositoryImpl(local);
  });

  SettingsRow buildRow({
    String themeMode = 'system',
    bool notificationsEnabled = true,
    bool appointmentsCompletionEnabled = false,
    bool completedToBottom = true,
    bool appointmentsCompletedToBottom = true,
    bool appointmentsTodayOnTop = true,
    bool invertSwipeActions = false,
    bool use24HourFormat = true,
    String appointmentReminderMinutes = '30',
    bool longPressHintSeen = false,
    int trashRetentionDays = defaultTrashRetentionDays,
    int skippedUpdateBuild = noSkippedUpdateBuild,
    DateTime? lastUpdateCheckAt,
  }) {
    return SettingsRow(
      id: 1,
      themeMode: themeMode,
      notificationsEnabled: notificationsEnabled,
      appointmentsCompletionEnabled: appointmentsCompletionEnabled,
      completedToBottom: completedToBottom,
      appointmentsCompletedToBottom: appointmentsCompletedToBottom,
      appointmentsTodayOnTop: appointmentsTodayOnTop,
      invertSwipeActions: invertSwipeActions,
      use24HourFormat: use24HourFormat,
      appointmentReminderMinutes: appointmentReminderMinutes,
      longPressHintSeen: longPressHintSeen,
      trashRetentionDays: trashRetentionDays,
      skippedUpdateBuild: skippedUpdateBuild,
      lastUpdateCheckAt: lastUpdateCheckAt,
      updatedAt: DateTime.utc(2026, 6, 30, 12),
    );
  }

  group('SettingsRepositoryImpl.load', () {
    test('mapea SettingsRow a AppSettings (defaults)', () async {
      when(() => local.getOrCreate()).thenAnswer((_) async => buildRow());

      final result = await repo.load();

      expect(result.themeMode, ThemeMode.system);
      expect(result.notificationsEnabled, isTrue);
      expect(result.appointmentsCompletionEnabled, isFalse);
      expect(result.completedToBottom, isTrue);
      expect(result.appointmentsCompletedToBottom, isTrue);
      expect(result.appointmentsTodayOnTop, isTrue);
      expect(result.invertSwipeActions, isFalse);
      expect(result.use24HourFormat, isTrue);
      expect(result.appointmentReminderMinutes, [30]);
      expect(result.longPressHintSeen, isFalse);
      expect(result.trashRetentionDays, 30);
      expect(result.skippedUpdateBuild, noSkippedUpdateBuild);
      expect(result.lastUpdateCheckAt, isNull);
    });

    test('copia la versión descartada y la última comprobación', () async {
      final checkedAt = DateTime.utc(2026, 10, 12, 9);
      when(() => local.getOrCreate()).thenAnswer(
        (_) async => buildRow(skippedUpdateBuild: 231, lastUpdateCheckAt: checkedAt),
      );

      final result = await repo.load();

      expect(result.skippedUpdateBuild, 231);
      expect(result.lastUpdateCheckAt, checkedAt);
    });

    test('lee los días que aguanta la papelera', () async {
      when(
        () => local.getOrCreate(),
      ).thenAnswer((_) async => buildRow(trashRetentionDays: 15));

      final result = await repo.load();

      expect(result.trashRetentionDays, 15);
    });

    test('un valor que el ajuste no ofrece cae al plazo de fábrica', () async {
      when(
        () => local.getOrCreate(),
      ).thenAnswer((_) async => buildRow(trashRetentionDays: 5));

      final result = await repo.load();

      expect(result.trashRetentionDays, 30);
    });

    test('mapea longPressHintSeen desde la fila', () async {
      when(
        () => local.getOrCreate(),
      ).thenAnswer((_) async => buildRow(longPressHintSeen: true));

      final result = await repo.load();

      expect(result.longPressHintSeen, isTrue);
    });

    test('lee la lista de márgenes guardada', () async {
      when(
        () => local.getOrCreate(),
      ).thenAnswer((_) async => buildRow(appointmentReminderMinutes: '0,60'));

      final result = await repo.load();

      expect(result.appointmentReminderMinutes, [0, 60]);
    });

    test('un valor guardado sin márgenes deja la cita sin avisos', () async {
      when(
        () => local.getOrCreate(),
      ).thenAnswer((_) async => buildRow(appointmentReminderMinutes: ''));

      final result = await repo.load();

      expect(result.appointmentReminderMinutes, isEmpty);
    });

    test('parsea themeMode "dark" como ThemeMode.dark', () async {
      when(
        () => local.getOrCreate(),
      ).thenAnswer((_) async => buildRow(themeMode: 'dark'));

      final result = await repo.load();

      expect(result.themeMode, ThemeMode.dark);
    });

    test('parsea themeMode "light" como ThemeMode.light', () async {
      when(
        () => local.getOrCreate(),
      ).thenAnswer((_) async => buildRow(themeMode: 'light'));

      final result = await repo.load();

      expect(result.themeMode, ThemeMode.light);
    });
  });

  group('SettingsRepositoryImpl.watch', () {
    test('mapea cada fila del stream a AppSettings', () async {
      final controller = StreamController<SettingsRow>();
      when(() => local.watch()).thenAnswer((_) => controller.stream);

      final emitted = <AppSettings>[];
      final sub = repo.watch().listen(emitted.add);

      controller.add(buildRow(themeMode: 'dark', notificationsEnabled: false));
      await Future<void>.delayed(Duration.zero);

      expect(emitted, hasLength(1));
      expect(emitted.first.themeMode, ThemeMode.dark);
      expect(emitted.first.notificationsEnabled, isFalse);

      await sub.cancel();
      await controller.close();
    });
  });

  group('SettingsRepositoryImpl.setThemeMode', () {
    test(
      'serializa ThemeMode.dark a "dark" vía AppSettings.themeModeToString',
      () async {
        when(() => local.updateThemeMode(any())).thenAnswer((_) async {});

        await repo.setThemeMode(ThemeMode.dark);

        verify(() => local.updateThemeMode('dark')).called(1);
      },
    );

    test('serializa ThemeMode.system a "system"', () async {
      when(() => local.updateThemeMode(any())).thenAnswer((_) async {});

      await repo.setThemeMode(ThemeMode.system);

      verify(() => local.updateThemeMode('system')).called(1);
    });
  });

  group('SettingsRepositoryImpl setters booleanos', () {
    test('delegan en los métodos del local sin transformación', () async {
      when(
        () => local.updateNotificationsEnabled(any()),
      ).thenAnswer((_) async {});
      when(
        () => local.updateAppointmentsCompletionEnabled(any()),
      ).thenAnswer((_) async {});
      when(() => local.updateCompletedToBottom(any())).thenAnswer((_) async {});
      when(
        () => local.updateAppointmentsCompletedToBottom(any()),
      ).thenAnswer((_) async {});
      when(
        () => local.updateAppointmentsTodayOnTop(any()),
      ).thenAnswer((_) async {});
      when(
        () => local.updateInvertSwipeActions(any()),
      ).thenAnswer((_) async {});
      when(() => local.updateUse24HourFormat(any())).thenAnswer((_) async {});
      when(() => local.updateLongPressHintSeen(any())).thenAnswer((_) async {});

      await repo.setNotificationsEnabled(false);
      await repo.setAppointmentsCompletionEnabled(true);
      await repo.setCompletedToBottom(false);
      await repo.setAppointmentsCompletedToBottom(false);
      await repo.setAppointmentsTodayOnTop(false);
      await repo.setInvertSwipeActions(true);
      await repo.setUse24HourFormat(false);
      await repo.setLongPressHintSeen(true);

      verify(() => local.updateNotificationsEnabled(false)).called(1);
      verify(() => local.updateAppointmentsCompletionEnabled(true)).called(1);
      verify(() => local.updateCompletedToBottom(false)).called(1);
      verify(() => local.updateAppointmentsCompletedToBottom(false)).called(1);
      verify(() => local.updateAppointmentsTodayOnTop(false)).called(1);
      verify(() => local.updateInvertSwipeActions(true)).called(1);
      verify(() => local.updateUse24HourFormat(false)).called(1);
      verify(() => local.updateLongPressHintSeen(true)).called(1);
    });
  });

  group('SettingsRepositoryImpl.setTrashRetentionDays', () {
    test('delega los días en el local', () async {
      when(() => local.updateTrashRetentionDays(any())).thenAnswer((_) async {});

      await repo.setTrashRetentionDays(30);

      verify(() => local.updateTrashRetentionDays(30)).called(1);
    });
  });

  group('SettingsRepositoryImpl.setAppointmentReminderMinutes', () {
    test('guarda la lista de márgenes en su forma canónica', () async {
      when(
        () => local.updateAppointmentReminderMinutes(any()),
      ).thenAnswer((_) async {});

      await repo.setAppointmentReminderMinutes(const [1440, 30, 30]);

      verify(() => local.updateAppointmentReminderMinutes('30,1440')).called(1);
    });
  });
}
