import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/core/theme/app_spacing.dart';
import '../../../../shared/core/theme/app_theme.dart';
import '../../../../shared/core/theme/app_typography.dart';
import '../../../../shared/ui/inputs/app_filter_chip.dart';
import '../../domain/entities/app_settings.dart';
import '../providers/settings_provider.dart';
import '../providers/settings_state.dart';
import 'reminder_lead_picker.dart';
import 'settings_tile.dart';

/// Cantidad con la que se abre el personalizado cuando todavía no hay ninguno:
/// un aviso de cuarto de hora es un punto de partida razonable.
const int _defaultCustomMinutes = 15;

/// Recordatorios de una cita: hasta [maxAppointmentReminders] márgenes, cada uno
/// en su chip.
///
/// Los que no caben —con el límite alcanzado— se quedan sin responder, así que
/// nunca cambia sola una elección ya hecha: para meter otro hay que quitar uno.
class AppointmentReminderSelector extends ConsumerWidget {
  const AppointmentReminderSelector({
    super.key,
    this.isFirst = true,
    this.isLast = true,
  });

  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(appointmentReminderMinutesProvider);
    // Sin preferencias leídas no sabemos qué márgenes hay: los chips se quedan
    // sin responder.
    final loadFailed = ref.watch(settingsProvider) is SettingsError;
    final custom = customReminderMinutes(selected);
    final atLimit = selected.length >= maxAppointmentReminders;

    /// Un margen que ya está puesto siempre se puede quitar; uno nuevo solo si
    /// queda hueco.
    bool canPick(int minutes) =>
        !loadFailed && (selected.contains(minutes) || !atLimit);

    void setMinutes(List<int> minutes) => ref
        .read(settingsProvider.notifier)
        .setAppointmentReminderMinutes(minutes);

    Future<void> pickCustom() async {
      final choice = await showReminderLeadPicker(
        context,
        initialMinutes: custom ?? _defaultCustomMinutes,
        removable: custom != null,
      );
      if (choice == null) return;

      // El valor de partida es el que haya guardado ahora, no el que tenía la
      // fila cuando se abrió el selector.
      final current = ref.read(appointmentReminderMinutesProvider);
      setMinutes(switch (choice) {
        ReminderLeadCleared() =>
          current
              .where((minutes) => minutes != customReminderMinutes(current))
              .toList(),
        ReminderLeadChosen(:final minutes) => setCustomReminderMinutes(
          current,
          minutes,
        ),
      });
    }

    return SettingsTile(
      icon: Icons.alarm_rounded,
      title: 'Recordatorio',
      enabled: !loadFailed,
      isFirst: isFirst,
      isLast: isLast,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final preset in AppointmentReminderPreset.values)
                AppFilterChip(
                  label: formatReminderLead(preset.minutes),
                  selected: selected.contains(preset.minutes),
                  onTap: canPick(preset.minutes)
                      ? () => setMinutes(
                          toggleReminderMinutes(selected, preset.minutes),
                        )
                      : null,
                ),
              AppFilterChip(
                // Con valor, el chip dice cuál es y de dónde sale: si solo
                // pusiera «45 min» parecería un preset más.
                label: custom == null
                    ? 'Personalizado'
                    : 'Personalizado: ${formatReminderLead(custom)}',
                selected: custom != null,
                // El personalizado puesto siempre se puede tocar —es la única
                // forma de cambiarlo o de quitarlo—; uno sin poner solo si
                // queda hueco.
                onTap: !loadFailed && (custom != null || !atLimit)
                    ? pickCustom
                    : null,
              ),
            ],
          ),
          if (atLimit) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Máximo $maxAppointmentReminders recordatorios: quita uno para '
              'añadir otro.',
              style: AppTypography.bodySm.copyWith(color: context.colors.body),
            ),
          ],
        ],
      ),
    );
  }
}

/// Cómo se lee un margen en Ajustes: «10 min», «1 h», «3 días».
///
/// El cero ya no se ofrece —el aviso a la hora de la cita se quitó de los
/// presets—, pero sigue leyéndose así: es el margen que quedó guardado en quien
/// lo tuviera puesto.
String formatReminderLead(int minutes) {
  if (minutes <= 0) return 'A la hora';
  if (minutes % 1440 == 0) {
    final days = minutes ~/ 1440;
    return days == 1 ? '1 día' : '$days días';
  }
  if (minutes % 60 == 0) return '${minutes ~/ 60} h';
  return '$minutes min';
}
