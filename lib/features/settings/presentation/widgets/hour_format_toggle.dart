import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_provider.dart';
import '../providers/settings_state.dart';
import 'settings_tile.dart';

/// Toggle para alternar entre formato 24H y 12H en las citas.
class HourFormatToggle extends ConsumerWidget {
  const HourFormatToggle({super.key, this.isFirst = true, this.isLast = true});

  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return SettingsTile(
      icon: Icons.schedule_rounded,
      title: 'Formato 24 horas',
      description:
          'Muestra las horas en formato 24H (ej. 14:00) en lugar de 12H '
          '(ej. 02:00 PM).',
      enabled: state is! SettingsError,
      isFirst: isFirst,
      isLast: isLast,
      trailing: SettingsSwitch(
        state: state,
        value: (settings) => settings.use24HourFormat,
        onChanged: notifier.setUse24HourFormat,
      ),
    );
  }
}
