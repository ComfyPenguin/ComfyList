import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_provider.dart';
import '../providers/settings_state.dart';
import 'settings_tile.dart';

/// Toggle para activar/desactivar la opción de marcar citas como completadas.
class AppointmentsCompletionToggle extends ConsumerWidget {
  const AppointmentsCompletionToggle({
    super.key,
    this.isFirst = true,
    this.isLast = true,
  });

  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return SettingsTile(
      icon: Icons.check_circle_outline_rounded,
      title: 'Completar citas',
      description: 'Permite marcar las citas como completadas con un checkbox.',
      isFirst: isFirst,
      isLast: isLast,
      trailing: switch (state) {
        SettingsData(:final settings) => Switch.adaptive(
          value: settings.appointmentsCompletionEnabled,
          onChanged: notifier.setAppointmentsCompletionEnabled,
        ),
        SettingsError() => const SettingsTileError(),
        SettingsInitial() || SettingsLoading() => const SettingsTileSpinner(),
      },
    );
  }
}
