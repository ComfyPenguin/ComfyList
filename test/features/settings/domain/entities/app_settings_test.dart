import 'package:comfy_list/features/settings/domain/entities/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppSettings.defaults', () {
    test('coincide con la baseline documentada', () {
      const defaults = AppSettings.defaults;

      expect(defaults.themeMode, ThemeMode.system);
      expect(defaults.notificationsEnabled, isFalse);
      expect(defaults.completedToBottom, isTrue);
      expect(defaults.appointmentsCompletedToBottom, isTrue);
      expect(defaults.appointmentsTodayOnTop, isTrue);
      expect(defaults.invertSwipeActions, isFalse);
      expect(defaults.use24HourFormat, isTrue);
      expect(defaults.longPressHintSeen, isFalse);
      expect(defaults.trashRetentionDays, 30);
      expect(defaults.emptiesTrashItself, isTrue);
    });
  });

  group('AppSettings.copyWith', () {
    test('cambia solo los campos suministrados', () {
      const baseline = AppSettings.defaults;

      final updated = baseline.copyWith(themeMode: ThemeMode.dark);

      expect(updated.themeMode, ThemeMode.dark);
      expect(updated.notificationsEnabled, baseline.notificationsEnabled);
      expect(updated.completedToBottom, baseline.completedToBottom);
      expect(
        updated.appointmentsCompletedToBottom,
        baseline.appointmentsCompletedToBottom,
      );
      expect(updated.appointmentsTodayOnTop, baseline.appointmentsTodayOnTop);
      expect(updated.invertSwipeActions, baseline.invertSwipeActions);
      expect(updated.use24HourFormat, baseline.use24HourFormat);
      expect(updated.longPressHintSeen, baseline.longPressHintSeen);
      expect(updated.trashRetentionDays, baseline.trashRetentionDays);
    });

    test('devuelve una instancia nueva (inmutable)', () {
      const baseline = AppSettings.defaults;

      final updated = baseline.copyWith(notificationsEnabled: true);

      expect(identical(updated, baseline), isFalse);
      expect(
        baseline.notificationsEnabled,
        isFalse,
        reason: 'La instancia original no debe mutar.',
      );
    });

    test('acepta varios campos a la vez', () {
      const baseline = AppSettings.defaults;

      final updated = baseline.copyWith(
        themeMode: ThemeMode.light,
        use24HourFormat: false,
        completedToBottom: false,
        appointmentsCompletedToBottom: false,
        appointmentsTodayOnTop: false,
        invertSwipeActions: true,
        longPressHintSeen: true,
        trashRetentionDays: 30,
      );

      expect(updated.themeMode, ThemeMode.light);
      expect(updated.use24HourFormat, isFalse);
      expect(updated.completedToBottom, isFalse);
      expect(updated.appointmentsCompletedToBottom, isFalse);
      expect(updated.appointmentsTodayOnTop, isFalse);
      expect(updated.invertSwipeActions, isTrue);
      expect(updated.longPressHintSeen, isTrue);
      expect(updated.trashRetentionDays, 30);
      expect(updated.emptiesTrashItself, isTrue);
      expect(updated.notificationsEnabled, baseline.notificationsEnabled);
    });
  });

  group('AppSettings.parseTrashRetentionDays', () {
    test('deja pasar los plazos que ofrece el ajuste', () {
      for (final days in trashRetentionDayOptions) {
        expect(AppSettings.parseTrashRetentionDays(days), days);
      }
    });

    test('«nunca» es un valor más, no un hueco', () {
      expect(AppSettings.parseTrashRetentionDays(0), 0);
    });

    test('cualquier otro valor cae al plazo de fábrica', () {
      expect(AppSettings.parseTrashRetentionDays(5), 30);
      expect(AppSettings.parseTrashRetentionDays(-1), 30);
      expect(AppSettings.parseTrashRetentionDays(365), 30);
    });
  });

  group('AppSettings.parseThemeMode', () {
    test('mapea los tres valores conocidos', () {
      expect(AppSettings.parseThemeMode('light'), ThemeMode.light);
      expect(AppSettings.parseThemeMode('dark'), ThemeMode.dark);
      expect(AppSettings.parseThemeMode('system'), ThemeMode.system);
    });

    test('cae a ThemeMode.system con un valor desconocido', () {
      expect(AppSettings.parseThemeMode('nonsense'), ThemeMode.system);
      expect(AppSettings.parseThemeMode(''), ThemeMode.system);
    });
  });

  group('AppSettings.themeModeToString', () {
    test('serializa los tres valores a su forma canónica', () {
      expect(AppSettings.themeModeToString(ThemeMode.light), 'light');
      expect(AppSettings.themeModeToString(ThemeMode.dark), 'dark');
      expect(AppSettings.themeModeToString(ThemeMode.system), 'system');
    });

    test('es la inversa de parseThemeMode (round-trip seguro)', () {
      for (final mode in ThemeMode.values) {
        final encoded = AppSettings.themeModeToString(mode);
        final decoded = AppSettings.parseThemeMode(encoded);
        expect(decoded, mode);
      }
    });
  });
}
