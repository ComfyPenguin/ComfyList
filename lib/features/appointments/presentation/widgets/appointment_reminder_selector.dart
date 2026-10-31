import 'package:flutter/material.dart';

import '../../../../shared/core/theme/app_radius.dart';
import '../../../../shared/core/theme/app_spacing.dart';
import '../../../../shared/core/theme/app_stroke.dart';
import '../../../../shared/core/theme/app_theme.dart';
import '../../../../shared/core/theme/app_typography.dart';
import '../../../../shared/ui/buttons/primary_button.dart';
import '../../../../shared/ui/inputs/app_chip.dart';
import '../../../../shared/ui/inputs/field_notch.dart';
import '../../domain/reminder_minutes.dart';
import 'reminder_lead_labels.dart';
import 'reminder_lead_menu.dart';
import 'reminder_lead_picker.dart';

/// Cantidad con la que se abre la rueda del personalizado: veinte minutos no
/// salen entre los presets y es un punto de partida razonable.
const int _defaultCustomMinutes = 20;

/// Ritmo del botón de añadir al aparecer y desaparecer.
const Duration _revealDuration = Duration(milliseconds: 260);
const Curve _revealCurve = Curves.easeOutCubic;

/// Recordatorios de una cita: los que tenga puestos, cada uno en su pastilla, y
/// un botón para añadir más hasta [maxAppointmentReminders].
///
/// Es de quien lo monta: recibe los márgenes en [selected] y devuelve la lista
/// nueva por [onChanged], sin guardar nada por su cuenta. Se añaden desde el
/// menú —no hay opciones sueltas que encender— y se quitan tocando su pastilla.
/// Con el máximo puesto el botón se va, que ya no queda nada que ofrecer: entra
/// y sale con el hueco, no apagado.
class AppointmentReminderSelector extends StatelessWidget {
  const AppointmentReminderSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final List<int> selected;
  final ValueChanged<List<int>> onChanged;

  Future<void> _add(BuildContext context) async {
    final option = await showReminderLeadMenu(context, taken: selected);
    if (option == null || !context.mounted) return;

    switch (option) {
      case PresetReminderLead(:final minutes):
        onChanged(addReminderMinutes(selected, minutes));
      case CustomReminderLead():
        final minutes = await showReminderLeadPicker(
          context,
          initialMinutes: _defaultCustomMinutes,
        );
        if (minutes != null) onChanged(addReminderMinutes(selected, minutes));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // Con los cinco puestos no cabe ninguno más.
    final canAdd = selected.length < maxAppointmentReminders;

    OutlineInputBorder outline() => OutlineInputBorder(
      borderRadius: AppRadius.brTile,
      borderSide: BorderSide(color: colors.cardBorder, width: AppStroke.hairline),
    );

    return InputDecorator(
      // Con contenido siempre: la etiqueta flota sobre el borde, igual que en
      // los demás campos del formulario.
      isEmpty: false,
      decoration: InputDecoration(
        labelText: 'RECORDATORIOS',
        filled: true,
        fillColor: colors.canvas,
        contentPadding: FieldStyle.padding,
        labelStyle: AppTypography.bodySm.copyWith(color: colors.body),
        floatingLabelStyle: AppTypography.fieldLabel(colors.ink),
        border: outline(),
        enabledBorder: outline(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (selected.isNotEmpty)
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final minutes in selected)
                  AppChip(
                    label: formatReminderLead(minutes),
                    onDelete: () =>
                        onChanged(removeReminderMinutes(selected, minutes)),
                  ),
              ],
            ),
          // El botón entra y sale con su hueco: vuelve al quitar una pastilla y
          // se va al poner la quinta. Se animan el hueco y el fundido, no un
          // despliegue recortado: el recorte le cortaría el halo al botón.
          AnimatedAlign(
            alignment: Alignment.topCenter,
            heightFactor: canAdd ? 1 : 0,
            duration: _revealDuration,
            curve: _revealCurve,
            child: ExcludeSemantics(
              excluding: !canAdd,
              child: IgnorePointer(
                ignoring: !canAdd,
                child: AnimatedOpacity(
                  opacity: canAdd ? 1 : 0,
                  duration: _revealDuration,
                  curve: _revealCurve,
                  child: Padding(
                    // Con pastillas puestas va separado de ellas; sin ninguna,
                    // pegado al título.
                    padding: EdgeInsets.only(
                      top: selected.isEmpty ? 0 : AppSpacing.lg,
                    ),
                    child: PrimaryButton(
                      label: 'Añadir recordatorio',
                      icon: Icons.add_rounded,
                      onPressed: () => _add(context),
                      expand: true,
                      dense: true,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
