import 'package:comfy_list/features/settings/domain/entities/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppSettings.parseThemeMode', () {
    test('reconoce light/dark/system', () {
      expect(AppSettings.parseThemeMode('light'), ThemeMode.light);
      expect(AppSettings.parseThemeMode('dark'), ThemeMode.dark);
      expect(AppSettings.parseThemeMode('system'), ThemeMode.system);
    });

    test('cae a system con valores desconocidos', () {
      expect(AppSettings.parseThemeMode('unknown'), ThemeMode.system);
      expect(AppSettings.parseThemeMode(''), ThemeMode.system);
    });
  });

  test('themeModeToString es estable', () {
    expect(AppSettings.themeModeToString(ThemeMode.light), 'light');
    expect(AppSettings.themeModeToString(ThemeMode.dark), 'dark');
    expect(AppSettings.themeModeToString(ThemeMode.system), 'system');
  });

  test('copyWith preserva campos no tocados', () {
    const initial = AppSettings.defaults;
    final next = initial.copyWith(themeMode: ThemeMode.dark);
    expect(next.themeMode, ThemeMode.dark);
    expect(next.notificationsEnabled, initial.notificationsEnabled);
  });
}
