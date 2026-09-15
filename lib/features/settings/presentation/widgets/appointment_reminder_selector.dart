import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/ui/inputs/app_segmented_control.dart';
import '../../domain/entities/app_settings.dart';
import '../providers/settings_provider.dart';
import '../providers/settings_state.dart';
import 'settings_tile.dart';

/// Selector de cuánto antes avisa el recordatorio de una cita.
class AppointmentReminderSelector extends ConsumerWidget {
  const AppointmentReminderSelector({
    super.key,
    this.isFirst = true,
    this.isLast = true,
  });

  final bool isFirst;
  final bool isLast;

  static const List<AppSegmentOption<AppointmentReminderLead>> _options = [
    AppSegmentOption(value: AppointmentReminderLead.atTime, label: 'A la hora'),
    AppSegmentOption(
      value: AppointmentReminderLead.tenMinutes,
      label: '10 min',
    ),
    AppSegmentOption(
      value: AppointmentReminderLead.thirtyMinutes,
      label: '30 min',
    ),
    AppSegmentOption(value: AppointmentReminderLead.oneHour, label: '1 h'),
    AppSegmentOption(value: AppointmentReminderLead.oneDay, label: '1 día'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lead = ref.watch(appointmentReminderLeadProvider);
    final notifier = ref.read(settingsProvider.notifier);
    // Sin preferencias leídas no sabemos qué margen está guardado: el control
    // se queda sin opción marcada y sin responder.
    final loadFailed = ref.watch(settingsProvider) is SettingsError;
    final selectedIndex = loadFailed
        ? -1
        : _options.indexWhere((o) => o.value == lead);

    return SettingsTile(
      icon: Icons.alarm_rounded,
      title: 'Recordatorio',
      enabled: !loadFailed,
      isFirst: isFirst,
      isLast: isLast,
      child: AppSegmentedControl(
        options: _options,
        selectedIndex: selectedIndex,
        enabled: !loadFailed,
        onSelected: (index) =>
            notifier.setAppointmentReminderLead(_options[index].value),
      ),
    );
  }
}
