import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_provider.dart';
import '../providers/settings_state.dart';
import 'settings_tile.dart';

/// Toggle para decidir si las tareas completadas se mueven al final de la lista.
class CompletedToBottomToggle extends ConsumerWidget {
  const CompletedToBottomToggle({
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
      icon: Icons.vertical_align_bottom_rounded,
      title: 'Tareas completadas al final',
      enabled: state is! SettingsError,
      isFirst: isFirst,
      isLast: isLast,
      trailing: SettingsSwitch(
        state: state,
        value: (settings) => settings.completedToBottom,
        onChanged: notifier.setCompletedToBottom,
      ),
    );
  }
}
