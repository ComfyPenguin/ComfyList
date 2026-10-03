import 'package:comfy_list/features/settings/domain/entities/app_settings.dart';
import 'package:comfy_list/features/settings/domain/repositories/settings_repository.dart';
import 'package:comfy_list/features/settings/presentation/providers/settings_provider.dart';
import 'package:comfy_list/features/settings/presentation/providers/settings_state.dart';
import 'package:comfy_list/shared/core/failures/failure.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/provider_scope.dart';

class _MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  late _MockSettingsRepository repo;
  late ProviderContainer container;

  setUp(() {
    repo = _MockSettingsRepository();
    container = createTestContainer(
      withInMemoryDb: true,
      repositoryOverrides: {SettingsRepository: repo},
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('SettingsNotifier bootstrap', () {
    test('transita Initial → Loading → Data con defaults', () async {
      when(() => repo.load()).thenAnswer((_) async => AppSettings.defaults);
      when(() => repo.watch()).thenAnswer((_) => const Stream.empty());

      final notifier = container.read(settingsProvider.notifier);
      expect(container.read(settingsProvider), isA<SettingsInitial>());

      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      final state = container.read(settingsProvider);
      expect(state, isA<SettingsData>(),
          reason: 'Debe llegar a Data con AppSettings.defaults.');
      expect((state as SettingsData).settings, AppSettings.defaults);
      expect(notifier, isNotNull);
    });
  });

  group('SettingsNotifier.setThemeMode', () {
    test('persiste en el repositorio', () async {
      when(() => repo.load()).thenAnswer((_) async => AppSettings.defaults);
      when(() => repo.watch()).thenAnswer((_) => const Stream.empty());
      when(() => repo.setThemeMode(ThemeMode.dark)).thenAnswer((_) async {});

      container.read(settingsProvider.notifier);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      await container
          .read(settingsProvider.notifier)
          .setThemeMode(ThemeMode.dark);

      verify(() => repo.setThemeMode(ThemeMode.dark)).called(1);
    });
  });

  group('SettingsNotifier.setLongPressHintSeen', () {
    test('persiste la marca en el repositorio', () async {
      when(() => repo.load()).thenAnswer((_) async => AppSettings.defaults);
      when(() => repo.watch()).thenAnswer((_) => const Stream.empty());
      when(() => repo.setLongPressHintSeen(true)).thenAnswer((_) async {});

      container.read(settingsProvider.notifier);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      await container
          .read(settingsProvider.notifier)
          .setLongPressHintSeen(true);

      verify(() => repo.setLongPressHintSeen(true)).called(1);
    });
  });

  group('SettingsNotifier error path', () {
    test('un error en load() surface como SettingsError(CacheFailure)',
        () async {
      when(() => repo.load()).thenThrow(StateError('DAO cerrado mid-test'));

      container.read(settingsProvider.notifier);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      final state = container.read(settingsProvider);
      expect(state, isA<SettingsError>());
      expect((state as SettingsError).failure, isA<CacheFailure>(),
          reason:
              'Cualquier excepción no-Failure en load() debe envolverse en CacheFailure.');
    });

    test('una Failure concreta en load() se propaga tal cual', () async {
      when(() => repo.load())
          .thenThrow(const UnknownFailure('algo salió mal'));

      container.read(settingsProvider.notifier);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      final state = container.read(settingsProvider);
      expect(state, isA<SettingsError>());
      expect((state as SettingsError).failure, isA<UnknownFailure>());
    });
  });
}
