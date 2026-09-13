import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_provider.dart';
import '../providers/settings_state.dart';
import 'settings_tile.dart';

/// Toggle para invertir el lado de las acciones del deslizamiento:
/// al activarlo, «Eliminar» queda a la izquierda y «Completar» a la derecha.
class InvertSwipeActionsToggle extends ConsumerWidget {
  const InvertSwipeActionsToggle({
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
      icon: Icons.swap_horiz_rounded,
      title: 'Invertir acciones al deslizar',
      enabled: state is! SettingsError,
      isFirst: isFirst,
      isLast: isLast,
      trailing: SettingsSwitch(
        state: state,
        value: (settings) => settings.invertSwipeActions,
        onChanged: notifier.setInvertSwipeActions,
      ),
    );
  }
}
