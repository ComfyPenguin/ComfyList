import 'package:flutter/foundation.dart';

import '../../../../shared/core/failures/failure.dart';
import '../../domain/entities/app_settings.dart';

@immutable
sealed class SettingsState {
  const SettingsState();
}

class SettingsInitial extends SettingsState {
  const SettingsInitial();
}

class SettingsLoading extends SettingsState {
  const SettingsLoading();
}

class SettingsData extends SettingsState {
  const SettingsData(this.settings);
  final AppSettings settings;
}

class SettingsError extends SettingsState {
  const SettingsError(this.failure);
  final Failure failure;
}
