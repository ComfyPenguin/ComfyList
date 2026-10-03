import 'package:comfy_list/features/settings/domain/entities/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppSettings.defaults', () {
    test('coincide con la baseline documentada', () {
      const defaults = AppSettings.defaults;

      expect(defaults.themeMode, ThemeMode.system);
      expect(defaults.notificationsEnabled, isFalse);
      expect(defaults.appointmentsCompletionEnabled, isFalse);
      expect(defaults.completedToBottom, isTrue);
      expect(defaults.appointmentsCompletedToBottom, isTrue);
      expect(defaults.appointmentsTodayOnTop, isTrue);
      expect(defaults.invertSwipeActions, isFalse);
      expect(defaults.use24HourFormat, isTrue);
      expect(defaults.appointmentReminderMinutes, [30]);
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
      expect(
        updated.appointmentsCompletionEnabled,
        baseline.appointmentsCompletionEnabled,
      );
      expect(updated.completedToBottom, baseline.completedToBottom);
      expect(
        updated.appointmentsCompletedToBottom,
        baseline.appointmentsCompletedToBottom,
      );
      expect(updated.appointmentsTodayOnTop, baseline.appointmentsTodayOnTop);
      expect(updated.invertSwipeActions, baseline.invertSwipeActions);
      expect(updated.use24HourFormat, baseline.use24HourFormat);
      expect(
        updated.appointmentReminderMinutes,
        baseline.appointmentReminderMinutes,
      );
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
        appointmentReminderMinutes: const [5, 60],
        longPressHintSeen: true,
        trashRetentionDays: 30,
      );

      expect(updated.themeMode, ThemeMode.light);
      expect(updated.use24HourFormat, isFalse);
      expect(updated.completedToBottom, isFalse);
      expect(updated.appointmentsCompletedToBottom, isFalse);
      expect(updated.appointmentsTodayOnTop, isFalse);
      expect(updated.invertSwipeActions, isTrue);
      expect(updated.appointmentReminderMinutes, [5, 60]);
      expect(updated.longPressHintSeen, isTrue);
      expect(updated.trashRetentionDays, 30);
      expect(updated.emptiesTrashItself, isTrue);
      expect(updated.notificationsEnabled, baseline.notificationsEnabled);
      expect(
        updated.appointmentsCompletionEnabled,
        baseline.appointmentsCompletionEnabled,
      );
    });
  });

  group('AppSettings.normalizeReminderMinutes', () {
    test('ordena y quita repetidos', () {
      expect(AppSettings.normalizeReminderMinutes([1440, 5, 30, 5]), [
        5,
        30,
        1440,
      ]);
    });

    test('se queda con los cinco más cercanos a la cita', () {
      expect(AppSettings.normalizeReminderMinutes([1440, 60, 30, 5, 10, 15]), [
        5,
        10,
        15,
        30,
        60,
      ]);
    });

    test('descarta los negativos y deja pasar la lista vacía', () {
      expect(AppSettings.normalizeReminderMinutes([-5, 30]), [30]);
      expect(AppSettings.normalizeReminderMinutes(const []), isEmpty);
    });
  });

  group('AppSettings.reminderMinutesToString', () {
    test('guarda la lista canónica separada por comas', () {
      expect(AppSettings.reminderMinutesToString([1440, 30, 30]), '30,1440');
      expect(AppSettings.reminderMinutesToString(const []), '');
    });
  });

  group('AppSettings.parseReminderMinutes', () {
    test('lee lo guardado', () {
      expect(AppSettings.parseReminderMinutes('5,30,1440'), [5, 30, 1440]);
    });

    test('un valor vacío es «sin avisos»', () {
      expect(AppSettings.parseReminderMinutes(''), isEmpty);
    });

    test('descarta lo que no se puede leer', () {
      expect(AppSettings.parseReminderMinutes('60,,vaya,30'), [30, 60]);
    });

    test('es la inversa de reminderMinutesToString (round-trip seguro)', () {
      const minutes = [5, 30, 1440];
      expect(
        AppSettings.parseReminderMinutes(
          AppSettings.reminderMinutesToString(minutes),
        ),
        minutes,
      );
    });
  });

  group('addReminderMinutes', () {
    test('añade el margen en su sitio', () {
      expect(addReminderMinutes([30], 60), [30, 60]);
      expect(addReminderMinutes([30, 60], 15), [15, 30, 60]);
    });

    test('no añade repetidos', () {
      expect(addReminderMinutes([30, 60], 30), [30, 60]);
    });

    test('no deja pasar de cinco', () {
      expect(addReminderMinutes([5, 10, 15, 30, 60], 1440), [
        5,
        10,
        15,
        30,
        60,
      ]);
    });
  });

  group('removeReminderMinutes', () {
    test('saca el margen y deja el resto', () {
      expect(removeReminderMinutes([5, 30, 1440], 30), [5, 1440]);
    });

    test('sin el margen puesto no cambia nada', () {
      expect(removeReminderMinutes([30], 60), [30]);
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
