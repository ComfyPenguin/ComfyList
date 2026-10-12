import 'dart:async';

import 'package:comfy_list/features/settings/domain/entities/app_settings.dart';
import 'package:comfy_list/features/settings/domain/repositories/settings_repository.dart';
import 'package:comfy_list/shared/core/failures/failure.dart';
import 'package:flutter/material.dart';

/// Repositorio de ajustes en memoria: sirve [settings] al leer, emite por su
/// stream lo que se va guardando y puede simular un fallo de lectura con
/// [fail] (para el reintento de la pantalla de ajustes).
class FakeSettingsRepository implements SettingsRepository {
  FakeSettingsRepository({AppSettings? settings})
    : _settings = settings ?? AppSettings.defaults;

  /// Se incrementa en cada [load] — útil para comprobar el reintento.
  int loadCalls = 0;

  /// Con `true`, [load] lanza [CacheFailure] mientras no se baje a `false`.
  bool fail = false;

  AppSettings _settings;
  final _updates = StreamController<AppSettings>.broadcast();

  Future<void> close() => _updates.close();

  void _save(AppSettings next) {
    _settings = next;
    _updates.add(next);
  }

  @override
  Future<AppSettings> load() async {
    loadCalls++;
    if (fail) throw const CacheFailure();
    return _settings;
  }

  @override
  Stream<AppSettings> watch() => _updates.stream;

  @override
  Future<void> setThemeMode(ThemeMode mode) async =>
      _save(_settings.copyWith(themeMode: mode));

  @override
  Future<void> setNotificationsEnabled(bool enabled) async =>
      _save(_settings.copyWith(notificationsEnabled: enabled));

  @override
  Future<void> setAppointmentsCompletionEnabled(bool enabled) async =>
      _save(_settings.copyWith(appointmentsCompletionEnabled: enabled));

  @override
  Future<void> setCompletedToBottom(bool enabled) async =>
      _save(_settings.copyWith(completedToBottom: enabled));

  @override
  Future<void> setAppointmentsCompletedToBottom(bool enabled) async =>
      _save(_settings.copyWith(appointmentsCompletedToBottom: enabled));

  @override
  Future<void> setAppointmentsTodayOnTop(bool enabled) async =>
      _save(_settings.copyWith(appointmentsTodayOnTop: enabled));

  @override
  Future<void> setInvertSwipeActions(bool enabled) async =>
      _save(_settings.copyWith(invertSwipeActions: enabled));

  @override
  Future<void> setUse24HourFormat(bool enabled) async =>
      _save(_settings.copyWith(use24HourFormat: enabled));

  @override
  Future<void> setAppointmentReminderMinutes(List<int> minutes) async =>
      _save(_settings.copyWith(appointmentReminderMinutes: minutes));

  @override
  Future<void> setLongPressHintSeen(bool seen) async =>
      _save(_settings.copyWith(longPressHintSeen: seen));

  @override
  Future<void> setTrashRetentionDays(int days) async =>
      _save(_settings.copyWith(trashRetentionDays: days));

  @override
  Future<void> setSkippedUpdateBuild(int build) async =>
      _save(_settings.copyWith(skippedUpdateBuild: build));

  @override
  Future<void> setLastUpdateCheckAt(DateTime at) async =>
      _save(_settings.copyWith(lastUpdateCheckAt: at));
}
