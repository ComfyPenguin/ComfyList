import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/core/failures/failure.dart';
import '../../../../shared/data/local/database_provider.dart';
import '../../data/datasources/drift_settings_local.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import 'settings_state.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final dao = ref.watch(settingsDaoProvider);
  return SettingsRepositoryImpl(DriftSettingsLocal(dao));
});

/// Notifier con estado sellado [SettingsState].
/// Bootstrap asíncrono al construirse y suscripción al stream Drift
/// para mantener el estado sincronizado con cambios persistidos.
class SettingsNotifier extends Notifier<SettingsState> {
  StreamSubscription<AppSettings>? _sub;

  @override
  SettingsState build() {
    ref.onDispose(() => _sub?.cancel());
    Future.microtask(_bootstrap);
    return const SettingsInitial();
  }

  /// Vuelve a leer las preferencias tras un fallo, para el reintento de la
  /// pantalla de ajustes.
  Future<void> reload() => _bootstrap();

  Future<void> _bootstrap() async {
    state = const SettingsLoading();
    final repo = ref.read(settingsRepositoryProvider);
    try {
      final initial = await repo.load();
      state = SettingsData(initial);

      await _sub?.cancel();
      _sub = repo.watch().listen(
        (s) => state = SettingsData(s),
        onError: (Object e, StackTrace _) {
          state = SettingsError(e is Failure ? e : const CacheFailure());
        },
      );
    } catch (e) {
      state = SettingsError(e is Failure ? e : const CacheFailure());
    }
  }

  Future<void> setThemeMode(ThemeMode mode) =>
      ref.read(settingsRepositoryProvider).setThemeMode(mode);

  Future<void> setNotificationsEnabled(bool enabled) =>
      ref.read(settingsRepositoryProvider).setNotificationsEnabled(enabled);

  Future<void> setAppointmentsCompletionEnabled(bool enabled) =>
      ref.read(settingsRepositoryProvider).setAppointmentsCompletionEnabled(enabled);

  Future<void> setCompletedToBottom(bool enabled) =>
      ref.read(settingsRepositoryProvider).setCompletedToBottom(enabled);

  Future<void> setAppointmentsCompletedToBottom(bool enabled) =>
      ref
          .read(settingsRepositoryProvider)
          .setAppointmentsCompletedToBottom(enabled);

  Future<void> setAppointmentsTodayOnTop(bool enabled) =>
      ref.read(settingsRepositoryProvider).setAppointmentsTodayOnTop(enabled);

  Future<void> setInvertSwipeActions(bool enabled) =>
      ref.read(settingsRepositoryProvider).setInvertSwipeActions(enabled);

  Future<void> setUse24HourFormat(bool enabled) =>
      ref.read(settingsRepositoryProvider).setUse24HourFormat(enabled);

  Future<void> setAppointmentReminderMinutes(List<int> minutes) =>
      ref.read(settingsRepositoryProvider).setAppointmentReminderMinutes(minutes);

  Future<void> setLongPressHintSeen(bool seen) =>
      ref.read(settingsRepositoryProvider).setLongPressHintSeen(seen);
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, SettingsState>(SettingsNotifier.new);

/// Helper para `MaterialApp.themeMode` — devuelve `system` mientras carga.
final themeModeProvider = Provider<ThemeMode>((ref) {
  final state = ref.watch(settingsProvider);
  return switch (state) {
    SettingsData(:final settings) => settings.themeMode,
    _ => ThemeMode.system,
  };
});

/// Formato de hora elegido — devuelve el por defecto mientras carga.
final use24HourFormatProvider = Provider<bool>((ref) {
  final state = ref.watch(settingsProvider);
  return switch (state) {
    SettingsData(:final settings) => settings.use24HourFormat,
    _ => AppSettings.defaults.use24HourFormat,
  };
});

/// Márgenes de los recordatorios de citas — los de por defecto mientras carga.
final appointmentReminderMinutesProvider = Provider<List<int>>((ref) {
  final state = ref.watch(settingsProvider);
  return switch (state) {
    SettingsData(:final settings) => settings.appointmentReminderMinutes,
    _ => AppSettings.defaults.appointmentReminderMinutes,
  };
});
