import 'package:comfy_list/features/settings/data/datasources/drift_settings_local.dart';
import 'package:comfy_list/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:comfy_list/shared/data/local/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late SettingsRepositoryImpl repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = SettingsRepositoryImpl(DriftSettingsLocal(db.settingsDao));
  });

  tearDown(() async => db.close());

  test('load() crea defaults la primera vez', () async {
    final settings = await repo.load();
    expect(settings.themeMode, ThemeMode.system);
    expect(settings.notificationsEnabled, isTrue);
  });

  test('setThemeMode persiste y se refleja en load()', () async {
    await repo.load();
    await repo.setThemeMode(ThemeMode.dark);

    final reloaded = await repo.load();
    expect(reloaded.themeMode, ThemeMode.dark);
  });

  test('setNotificationsEnabled actualiza solo ese campo', () async {
    await repo.load();
    await repo.setThemeMode(ThemeMode.light);
    await repo.setNotificationsEnabled(false);

    final reloaded = await repo.load();
    expect(reloaded.themeMode, ThemeMode.light);
    expect(reloaded.notificationsEnabled, isFalse);
  });

  test('watch() emite tras una mutación', () async {
    await repo.load();
    final stream = repo.watch();

    final completer = stream.firstWhere((s) => s.themeMode == ThemeMode.dark);
    await repo.setThemeMode(ThemeMode.dark);
    final result = await completer;
    expect(result.themeMode, ThemeMode.dark);
  });
}
