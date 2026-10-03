import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/ui/inputs/app_segmented_control.dart';
import '../../domain/entities/app_settings.dart';
import '../providers/settings_provider.dart';
import '../providers/settings_state.dart';
import 'settings_tile.dart';

/// Cuánto aguanta un borrado en la papelera antes de que la app la vacíe sola.
class TrashRetentionSelector extends ConsumerWidget {
  const TrashRetentionSelector({
    super.key,
    this.isFirst = true,
    this.isLast = true,
  });

  final bool isFirst;
  final bool isLast;

  static final List<AppSegmentOption<int>> _options = [
    for (final days in trashRetentionDayOptions)
      AppSegmentOption(value: days, label: _label(days)),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = ref.watch(trashRetentionDaysProvider);
    final notifier = ref.read(settingsProvider.notifier);
    // Sin preferencias leídas no sabemos qué plazo está guardado: el control se
    // queda sin opción marcada y sin responder.
    final loadFailed = ref.watch(settingsProvider) is SettingsError;
    final selectedIndex = loadFailed
        ? -1
        : _options.indexWhere((option) => option.value == days);

    return SettingsTile(
      icon: Icons.auto_delete_outlined,
      title: 'Borrado automático',
      enabled: !loadFailed,
      isFirst: isFirst,
      isLast: isLast,
      child: AppSegmentedControl(
        options: _options,
        selectedIndex: selectedIndex,
        enabled: !loadFailed,
        onSelected: (index) =>
            notifier.setTrashRetentionDays(_options[index].value),
      ),
    );
  }
}

String _label(int days) => days == 0 ? 'Nunca' : '$days días';
