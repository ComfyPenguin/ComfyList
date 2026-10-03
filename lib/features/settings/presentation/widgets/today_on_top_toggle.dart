import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_provider.dart';
import '../providers/settings_state.dart';
import 'settings_tile.dart';

/// Toggle para mantener el día de hoy arriba del todo en la lista de citas,
/// aunque haya días pasados por delante.
class TodayOnTopToggle extends ConsumerWidget {
  const TodayOnTopToggle({super.key, this.isFirst = true, this.isLast = true});

  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return SettingsTile(
      icon: Icons.vertical_align_top_rounded,
      title: 'Citas de hoy arriba',
      enabled: state is! SettingsError,
      isFirst: isFirst,
      isLast: isLast,
      trailing: SettingsSwitch(
        state: state,
        value: (settings) => settings.appointmentsTodayOnTop,
        onChanged: notifier.setAppointmentsTodayOnTop,
      ),
    );
  }
}
