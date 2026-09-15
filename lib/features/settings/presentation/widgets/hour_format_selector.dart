import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/ui/inputs/app_segmented_control.dart';
import '../providers/settings_provider.dart';
import '../providers/settings_state.dart';
import 'settings_tile.dart';

/// Selector del formato de hora de las citas: 12H con AM/PM o 24H.
class HourFormatSelector extends ConsumerWidget {
  const HourFormatSelector({super.key, this.isFirst = true, this.isLast = true});

  final bool isFirst;
  final bool isLast;

  static const List<AppSegmentOption<bool>> _options = [
    AppSegmentOption(value: false, label: '12 h'),
    AppSegmentOption(value: true, label: '24 h'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final use24HourFormat = ref.watch(use24HourFormatProvider);
    final notifier = ref.read(settingsProvider.notifier);
    // Sin preferencias leídas no sabemos qué formato está guardado: el control
    // se queda sin opción marcada y sin responder.
    final loadFailed = ref.watch(settingsProvider) is SettingsError;
    final selectedIndex = loadFailed
        ? -1
        : _options.indexWhere((o) => o.value == use24HourFormat);

    return SettingsTile(
      icon: Icons.schedule_rounded,
      title: 'Formato de hora',
      enabled: !loadFailed,
      isFirst: isFirst,
      isLast: isLast,
      child: AppSegmentedControl(
        options: _options,
        selectedIndex: selectedIndex,
        enabled: !loadFailed,
        onSelected: (index) =>
            notifier.setUse24HourFormat(_options[index].value),
      ),
    );
  }
}
