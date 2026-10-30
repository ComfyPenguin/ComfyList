import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/core/failures/failure.dart';
import '../../../../shared/data/local/database_provider.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import 'settings_state.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final dao = ref.watch(settingsDaoProvider);
  return SettingsRepositoryImpl(dao);
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

  Future<void> setTrashRetentionDays(int days) =>
      ref.read(settingsRepositoryProvider).setTrashRetentionDays(days);

  Future<void> setSkippedUpdateBuild(int build) =>
      ref.read(settingsRepositoryProvider).setSkippedUpdateBuild(build);

  Future<void> setLastUpdateCheckAt(DateTime at) =>
      ref.read(settingsRepositoryProvider).setLastUpdateCheckAt(at);
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, SettingsState>(SettingsNotifier.new);

/// Los ajustes de la app, o los de fábrica mientras cargan o si no se pudieron
/// leer. Es lo que lee la pantalla: una sola respuesta a «qué valor tiene esto
/// ahora», sin que cada widget elija el suyo mientras carga. Quien necesite
/// distinguir «cargando» o «fallo» lee [settingsProvider].
final settingsOrDefaultsProvider = Provider<AppSettings>((ref) {
  return switch (ref.watch(settingsProvider)) {
    SettingsData(:final settings) => settings,
    _ => AppSettings.defaults,
  };
});

/// Helper para `MaterialApp.themeMode` — devuelve `system` mientras carga.
final themeModeProvider = Provider<ThemeMode>(
  (ref) => ref.watch(settingsOrDefaultsProvider.select((s) => s.themeMode)),
);

/// Formato de hora elegido — devuelve el por defecto mientras carga.
final use24HourFormatProvider = Provider<bool>(
  (ref) =>
      ref.watch(settingsOrDefaultsProvider.select((s) => s.use24HourFormat)),
);

/// Márgenes de los recordatorios de citas — los de por defecto mientras carga.
final appointmentReminderMinutesProvider = Provider<List<int>>(
  (ref) => ref.watch(
    settingsOrDefaultsProvider.select((s) => s.appointmentReminderMinutes),
  ),
);

/// Días que aguanta un borrado en la papelera (0 = nunca) — el de por defecto
/// mientras carga.
final trashRetentionDaysProvider = Provider<int>(
  (ref) => ref.watch(
    settingsOrDefaultsProvider.select((s) => s.trashRetentionDays),
  ),
);
