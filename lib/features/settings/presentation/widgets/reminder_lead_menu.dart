import 'package:flutter/material.dart';

import '../../../../shared/core/theme/app_radius.dart';
import '../../../../shared/core/theme/app_spacing.dart';
import '../../../../shared/core/theme/app_theme.dart';
import '../../../../shared/core/theme/app_typography.dart';
import '../../../../shared/ui/pickers/picker_sheet.dart';
import '../../domain/entities/app_settings.dart';
import 'reminder_lead_labels.dart';

/// Lo que se puede añadir desde el menú: un margen de los que ofrece Ajustes o
/// una cantidad elegida a mano.
sealed class ReminderLeadOption {
  const ReminderLeadOption();
}

/// Un margen de los presets, en minutos antes de la cita.
class PresetReminderLead extends ReminderLeadOption {
  const PresetReminderLead(this.minutes);

  final int minutes;
}

/// El usuario quiere elegir la cantidad en el selector.
class CustomReminderLead extends ReminderLeadOption {
  const CustomReminderLead();
}

/// Abre el menú de añadir recordatorio y devuelve lo que se eligió, o `null` si
/// se cierra sin elegir nada.
///
/// Los márgenes que la cita ya tiene no salen —repetir el mismo aviso no añade
/// nada—, y «Personalizada» sale siempre que haya un personalizado puesto, que
/// es por donde se cambia.
Future<ReminderLeadOption?> showReminderLeadMenu(
  BuildContext context, {
  required List<int> taken,
  required int? custom,
}) {
  return showModalBottomSheet<ReminderLeadOption>(
    context: context,
    // Sobre el Navigator raíz para que el sheet tape el TopBar del shell.
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => _ReminderLeadMenuSheet(taken: taken, custom: custom),
  );
}

class _ReminderLeadMenuSheet extends StatelessWidget {
  const _ReminderLeadMenuSheet({required this.taken, required this.custom});

  final List<int> taken;

  /// El margen personalizado que ya está puesto, si lo hay.
  final int? custom;

  @override
  Widget build(BuildContext context) {
    // Con los cinco puestos no cabe nada más, ni un preset ni un personalizado:
    // lo único que sigue teniendo sentido es cambiar el personalizado que ya
    // está.
    final hasRoom = taken.length < maxAppointmentReminders;
    final free = hasRoom
        ? AppointmentReminderPreset.values.where(
            (preset) => !taken.contains(preset.minutes),
          )
        : const <AppointmentReminderPreset>[];
    final customAvailable = custom != null || hasRoom;

    return PickerSheet(
      title: 'Añadir recordatorio',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final preset in free) ...[
            _MenuRow(
              label: formatReminderLeadBefore(preset.minutes),
              onTap: () =>
                  Navigator.of(context).pop(PresetReminderLead(preset.minutes)),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (customAvailable)
            _MenuRow(
              label: custom == null
                  ? 'Personalizada'
                  : 'Personalizada: ${formatReminderLead(custom!)}',
              onTap: () =>
                  Navigator.of(context).pop(const CustomReminderLead()),
            ),
        ],
      ),
    );
  }
}

/// Fila del menú: pastilla `canvasSoft` con el texto a la izquierda, que se elige
/// al tocarla.
class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Material(
      color: colors.canvasSoft,
      borderRadius: AppRadius.brPill,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          child: Text(
            label,
            style: AppTypography.bodyMdStrong.copyWith(color: colors.ink),
          ),
        ),
      ),
    );
  }
}
