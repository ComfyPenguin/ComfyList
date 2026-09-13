import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_provider.dart';
import '../providers/settings_state.dart';
import 'settings_tile.dart';

/// Toggle para decidir si las citas completadas se mueven al final de la
/// lista de su día. Solo tiene efecto cuando «Completar citas» está activo,
/// por eso el switch se deshabilita si no lo está.
class AppointmentsCompletedToBottomToggle extends ConsumerWidget {
  const AppointmentsCompletedToBottomToggle({
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

    final settings = switch (state) {
      SettingsData(:final settings) => settings,
      _ => null,
    };
    final enabled = settings?.appointmentsCompletionEnabled ?? false;

    return SettingsTile(
      icon: Icons.vertical_align_bottom_rounded,
      title: 'Citas completadas al final',
      description: enabled
          ? 'Las citas que marques como completadas se mueven al final de '
                'la lista de ese día automáticamente.'
          : 'Disponible al activar «Completar citas».',
      enabled: enabled,
      isFirst: isFirst,
      isLast: isLast,
      trailing: switch (state) {
        SettingsData() => Switch.adaptive(
          value: enabled ? settings!.appointmentsCompletedToBottom : false,
          onChanged: enabled
              ? notifier.setAppointmentsCompletedToBottom
              : null,
        ),
        SettingsError() => const SettingsTileError(),
        SettingsInitial() || SettingsLoading() => const SettingsTileSpinner(),
      },
    );
  }
}
