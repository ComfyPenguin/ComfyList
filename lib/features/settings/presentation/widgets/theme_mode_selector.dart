import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/ui/inputs/app_segmented_control.dart';
import '../providers/settings_provider.dart';
import '../providers/settings_state.dart';
import 'settings_tile.dart';

/// Selector de tema: control segmentado con sistema, claro y oscuro.
class ThemeModeSelector extends ConsumerWidget {
  const ThemeModeSelector({super.key, this.isFirst = true, this.isLast = true});

  final bool isFirst;
  final bool isLast;

  static const List<AppSegmentOption<ThemeMode>> _options = [
    AppSegmentOption(
      value: ThemeMode.system,
      label: 'Sistema',
      icon: Icons.brightness_auto_outlined,
    ),
    AppSegmentOption(
      value: ThemeMode.light,
      label: 'Claro',
      icon: Icons.light_mode_outlined,
    ),
    AppSegmentOption(
      value: ThemeMode.dark,
      label: 'Oscuro',
      icon: Icons.dark_mode_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final notifier = ref.read(settingsProvider.notifier);
    // Sin preferencias leídas no sabemos qué modo está guardado: el control se
    // queda sin opción marcada y sin responder.
    final loadFailed = ref.watch(settingsProvider) is SettingsError;
    final selectedIndex = loadFailed
        ? -1
        : _options.indexWhere((o) => o.value == mode);

    return SettingsTile(
      icon: Icons.palette_outlined,
      title: 'Tema',
      enabled: !loadFailed,
      isFirst: isFirst,
      isLast: isLast,
      child: AppSegmentedControl(
        options: _options,
        selectedIndex: selectedIndex,
        enabled: !loadFailed,
        onSelected: (index) => notifier.setThemeMode(_options[index].value),
      ),
    );
  }
}
