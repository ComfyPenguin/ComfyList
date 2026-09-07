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
    bool use24HourFormat = true,
  }) {
    return SettingsRow(
      id: 1,
      themeMode: themeMode,
      notificationsEnabled: notificationsEnabled,
      appointmentsCompletionEnabled: appointmentsCompletionEnabled,
      completedToBottom: completedToBottom,
      appointmentsCompletedToBottom: appointmentsCompletedToBottom,
      use24HourFormat: use24HourFormat,
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
      expect(result.use24HourFormat, isTrue);
    });

    test('parsea themeMode "dark" como ThemeMode.dark', () async {
      when(() => local.getOrCreate())
          .thenAnswer((_) async => buildRow(themeMode: 'dark'));

      final result = await repo.load();

      expect(result.themeMode, ThemeMode.dark);
    });

    test('parsea themeMode "light" como ThemeMode.light', () async {
      when(() => local.getOrCreate())
          .thenAnswer((_) async => buildRow(themeMode: 'light'));

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
    test('serializa ThemeMode.dark a "dark" vía AppSettings.themeModeToString',
        () async {
      when(() => local.updateThemeMode(any())).thenAnswer((_) async {});

      await repo.setThemeMode(ThemeMode.dark);

      verify(() => local.updateThemeMode('dark')).called(1);
    });

    test('serializa ThemeMode.system a "system"', () async {
      when(() => local.updateThemeMode(any())).thenAnswer((_) async {});

      await repo.setThemeMode(ThemeMode.system);

      verify(() => local.updateThemeMode('system')).called(1);
    });
  });

  group('SettingsRepositoryImpl setters booleanos', () {
    test('delegan en los métodos del local sin transformación', () async {
      when(() => local.updateNotificationsEnabled(any()))
          .thenAnswer((_) async {});
      when(() => local.updateAppointmentsCompletionEnabled(any()))
          .thenAnswer((_) async {});
      when(() => local.updateCompletedToBottom(any())).thenAnswer((_) async {});
      when(() => local.updateAppointmentsCompletedToBottom(any()))
          .thenAnswer((_) async {});
      when(() => local.updateUse24HourFormat(any())).thenAnswer((_) async {});

      await repo.setNotificationsEnabled(false);
      await repo.setAppointmentsCompletionEnabled(true);
      await repo.setCompletedToBottom(false);
      await repo.setAppointmentsCompletedToBottom(false);
      await repo.setUse24HourFormat(false);

      verify(() => local.updateNotificationsEnabled(false)).called(1);
      verify(() => local.updateAppointmentsCompletionEnabled(true)).called(1);
      verify(() => local.updateCompletedToBottom(false)).called(1);
      verify(() => local.updateAppointmentsCompletedToBottom(false)).called(1);
      verify(() => local.updateUse24HourFormat(false)).called(1);
    });
  });
}
