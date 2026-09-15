import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/core/theme/app_spacing.dart';
import '../../../../shared/ui/buttons/primary_button.dart';
import '../../../../shared/ui/inputs/app_chip.dart';
import '../../domain/entities/app_settings.dart';
import '../providers/settings_provider.dart';
import '../providers/settings_state.dart';
import 'reminder_lead_labels.dart';
import 'reminder_lead_menu.dart';
import 'reminder_lead_picker.dart';
import 'settings_tile.dart';

/// Cantidad con la que se abre la rueda del personalizado: veinte minutos no
/// salen entre los presets y es un punto de partida razonable.
const int _defaultCustomMinutes = 20;

/// Ritmo del botón de añadir al aparecer y desaparecer, el mismo que el de las
/// filas que se despliegan en Ajustes.
const Duration _revealDuration = Duration(milliseconds: 260);
const Curve _revealCurve = Curves.easeOutCubic;

/// Recordatorios de una cita: los que tenga puestos, cada uno en su pastilla, y
/// un botón para añadir más hasta [maxAppointmentReminders].
///
/// Se añaden desde el menú —no hay opciones sueltas que encender— y se quitan
/// tocando su pastilla. Con el máximo puesto el botón se va, que ya no queda
/// nada que ofrecer: entra y sale con el hueco, no apagado.
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
    // Sin preferencias leídas no sabemos qué márgenes hay: ni se quitan ni se
    // añaden.
    final loadFailed = ref.watch(settingsProvider) is SettingsError;
    // Con los cinco puestos no cabe ninguno más.
    final canAdd = !loadFailed && selected.length < maxAppointmentReminders;

    void setMinutes(List<int> minutes) => ref
        .read(settingsProvider.notifier)
        .setAppointmentReminderMinutes(minutes);

    Future<void> add() async {
      final option = await showReminderLeadMenu(context, taken: selected);
      if (option == null || !context.mounted) return;

      // Lo que haya guardado ahora, que puede no ser lo que la fila tenía al
      // abrir el menú.
      final current = ref.read(appointmentReminderMinutesProvider);
      switch (option) {
        case PresetReminderLead(:final minutes):
          setMinutes(addReminderMinutes(current, minutes));
        case CustomReminderLead():
          final minutes = await showReminderLeadPicker(
            context,
            initialMinutes: _defaultCustomMinutes,
          );
          if (minutes != null) {
            setMinutes(addReminderMinutes(current, minutes));
          }
      }
    }

    return SettingsTile(
      icon: Icons.alarm_rounded,
      title: 'Recordatorios',
      enabled: !loadFailed,
      isFirst: isFirst,
      isLast: isLast,
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
                    onDelete: loadFailed
                        ? null
                        : () => setMinutes(
                            removeReminderMinutes(selected, minutes),
                          ),
                  ),
              ],
            ),
          // El botón entra y sale con su hueco: vuelve al quitar una pastilla y
          // se va al poner la quinta. Se animan el hueco y el fundido, no un
          // despliegue recortado como el de las filas que cuelgan de un ajuste:
          // el recorte le cortaría el halo al botón.
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
                      onPressed: add,
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
