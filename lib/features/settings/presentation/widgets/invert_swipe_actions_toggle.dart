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
      description: switch (state) {
        SettingsData(:final settings) => settings.invertSwipeActions
            ? 'Deslizar a la derecha elimina y a la izquierda completa.'
            : 'Deslizar a la izquierda elimina y a la derecha completa.',
        _ => 'Elige hacia dónde elimina y hacia dónde completa al deslizar.',
      },
      isFirst: isFirst,
      isLast: isLast,
      trailing: switch (state) {
        SettingsData(:final settings) => Switch.adaptive(
          value: settings.invertSwipeActions,
          onChanged: notifier.setInvertSwipeActions,
        ),
        SettingsError() => const SettingsTileError(),
        SettingsInitial() || SettingsLoading() => const SettingsTileSpinner(),
      },
    );
  }
}
