import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/core/text/date_format.dart';
import '../../../../shared/core/time/clock.dart';
import '../../../../shared/core/theme/app_radius.dart';
import '../../../../shared/core/theme/app_spacing.dart';
import '../../../../shared/core/theme/app_stroke.dart';
import '../../../../shared/core/theme/app_theme.dart';
import '../../../../shared/core/theme/app_typography.dart';
import '../../../../shared/ui/buttons/primary_button.dart';
import '../../../../shared/ui/dialogs/confirm_action_dialog.dart';
import '../../../../shared/ui/inputs/app_text_field.dart';
import '../../../../shared/ui/inputs/field_notch.dart';
import '../../../../shared/ui/pickers/date_time_pickers.dart';
import '../../../../shared/ui/text/app_tag.dart';
import '../../../../shared/ui/toast/app_toast.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../domain/entities/repeat_rule.dart';
import '../../domain/reminder_minutes.dart';
import '../providers/appointments_provider.dart';
import '../providers/appointments_state.dart';
import '../widgets/appointment_reminder_selector.dart';
import '../widgets/reminder_warning.dart';
import '../widgets/repeat_rule_label.dart';
import '../widgets/repeat_rule_picker.dart';

/// Pantalla unificada de creación y edición de citas.
/// Si [id] es null → crear; si no → editar.
class AppointmentEditScreen extends ConsumerStatefulWidget {
  const AppointmentEditScreen({super.key, this.id});

  final String? id;

  @override
  ConsumerState<AppointmentEditScreen> createState() =>
      _AppointmentEditScreenState();
}

class _AppointmentEditScreenState extends ConsumerState<AppointmentEditScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  late DateTime _dateTime = ref.read(clockProvider)();
  RepeatRule? _repeatRule;
  List<int> _reminderMinutes = defaultReminderMinutes;
  String? _titleError;
  bool _hydrated = false;
  String _hydratedTitle = '';

  bool get _isEditing => widget.id != null;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  void _hydrateFromState(AppointmentsState s) {
    if (_hydrated || !_isEditing) return;
    if (s is AppointmentsData) {
      final appointment =
          s.items.where((a) => a.id == widget.id).firstOrNull;
      if (appointment != null) {
        _titleCtrl.text = appointment.title;
        _descCtrl.text = appointment.description ?? '';
        _locationCtrl.text = appointment.location ?? '';
        _dateTime = appointment.dateTime;
        _repeatRule = appointment.repeatRule;
        _reminderMinutes = appointment.reminderMinutes;
        _hydratedTitle = appointment.title;
        _hydrated = true;
      }
    }
  }

  Future<void> _pickDateTime() async {
    final pickedDate = await showAppDatePicker(context, initialDate: _dateTime);
    if (pickedDate == null) return;

    if (!mounted) return;
    final pickedTime = await showAppTimePicker(
      context,
      initialTime: TimeOfDay.fromDateTime(_dateTime),
      use24HourFormat: ref.read(use24HourFormatProvider),
    );
    if (pickedTime == null) return;

    setState(() {
      _dateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _pickRepeatRule() async {
    final picked = await showRepeatRulePicker(context, initial: _repeatRule);
    if (picked == null || !mounted) return;
    setState(() => _repeatRule = picked);
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      setState(() => _titleError = 'El título no puede estar vacío.');
      return;
    }
    setState(() => _titleError = null);

    final notifier = ref.read(appointmentsProvider.notifier);
    final desc = _descCtrl.text.trim();
    final loc = _locationCtrl.text.trim();

    final saved = _isEditing
        ? await notifier.updateFields(
            id: widget.id!,
            title: title,
            description: desc.isEmpty ? null : desc,
            clearDescription: desc.isEmpty,
            location: loc.isEmpty ? null : loc,
            clearLocation: loc.isEmpty,
            repeatRule: _repeatRule,
            clearRepeatRule: _repeatRule == null,
            reminderMinutes: _reminderMinutes,
            dateTime: _dateTime,
          )
        : await notifier.create(
            title: title,
            description: desc.isEmpty ? null : desc,
            location: loc.isEmpty ? null : loc,
            repeatRule: _repeatRule,
            reminderMinutes: _reminderMinutes,
            dateTime: _dateTime,
          );
    if (!mounted) return;

    // Sin guardar no se cierra: lo escrito se queda para reintentarlo.
    if (!saved) {
      AppToast.show(context, AppToast.saveFailed);
      return;
    }
    context.pop();
  }

  Future<void> _delete() async {
    if (!_isEditing) return;

    final router = GoRouter.of(context);

    final confirmed = await ConfirmActionDialog.show(
      context,
      title: '¿Eliminar cita?',
      message:
          '«$_hydratedTitle» se eliminará. Tendrás unos segundos para '
          'deshacerlo.',
      confirmLabel: 'Eliminar',
      destructive: true,
    );
    if (!confirmed) return;

    final notifier = ref.read(appointmentsProvider.notifier);
    final deleted = await notifier.delete(widget.id!);
    if (!mounted) return;

    if (deleted == null) {
      AppToast.show(context, AppToast.appointmentDeleteFailed);
      return;
    }
    AppToast.showUndo(
      context,
      message: AppToast.appointmentDeleted,
      onUndo: () => notifier.undo(deleted),
    );
    router.pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appointmentsProvider);
    final colors = context.colors;
    _hydrateFromState(state);

    // El formato de hora sigue el ajuste del usuario, igual que las tiles.
    final use24H = ref.watch(use24HourFormatProvider);
    final dateText = formatLongDate(_dateTime);
    final timeText = formatClockTimeWithPeriod(
      _dateTime,
      use24HourFormat: use24H,
    );

    // El TopBar del shell se superpone al contenido: reservamos su altura
    // (iconButton + padding del AppBar) más un margen hasta la primera card.
    final topOffset = MediaQuery.paddingOf(context).top + 56 + AppSpacing.md;

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          topOffset,
          AppSpacing.lg,
          AppSpacing.section,
        ),
        children: [
          // Mismo sangrado que las cabeceras de grupo de citas.
          const Padding(
            padding: EdgeInsets.only(left: AppSpacing.xl),
            child: Align(
              alignment: Alignment.centerLeft,
              child: AppTag(label: 'Así quedará tu cita'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _AppointmentPreview(
            titleCtrl: _titleCtrl,
            descriptionCtrl: _descCtrl,
            locationCtrl: _locationCtrl,
            dateTime: _dateTime,
            use24H: use24H,
          ),
          const SizedBox(height: AppSpacing.xxl),
          AppTextField(
            controller: _titleCtrl,
            label: 'Título',
            hint: '¿Qué cita tienes?',
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            errorText: _titleError,
            cardStyle: true,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _descCtrl,
            label: 'Notas (opcional)',
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            cardStyle: true,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _locationCtrl,
            label: 'Ubicación (opcional)',
            hint: '¿Dónde es la cita?',
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            cardStyle: true,
          ),
          const SizedBox(height: AppSpacing.md),
          // Fecha y hora como dos tiles unidas, con los mismos radios y
          // separación que las listas de la app. Las dos abren el mismo flujo
          // de selección, así que funcionan como un solo botón.
          BottomLabelNotch(
            label: 'Hora',
            child: _DateTimeTile(
              label: 'Fecha',
              value: dateText,
              borderRadius: const BorderRadius.vertical(
                top: AppRadius.rTile,
                bottom: AppRadius.rJoined,
              ),
              onTap: _pickDateTime,
            ),
          ),
          const SizedBox(height: AppSpacing.joined),
          _DateTimeTile(
            label: 'Hora',
            value: timeText,
            borderRadius: const BorderRadius.vertical(
              top: AppRadius.rJoined,
              bottom: AppRadius.rTile,
            ),
            onTap: _pickDateTime,
          ),
          // Justo debajo de la hora, que es lo que avisa el recordatorio.
          const ReminderWarning(),
          const SizedBox(height: AppSpacing.md),
          AppointmentReminderSelector(
            selected: _reminderMinutes,
            onChanged: (minutes) => setState(() => _reminderMinutes = minutes),
          ),
          const SizedBox(height: AppSpacing.md),
          _DateTimeTile(
            label: 'Repetir',
            value: _repeatRule == null
                ? 'No se repite'
                : repeatRuleLabel(_repeatRule!),
            borderRadius: AppRadius.brTile,
            onTap: _pickRepeatRule,
            trailing: _repeatRule == null
                ? null
                : IconButton(
                    tooltip: 'Quitar repetición',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => setState(() => _repeatRule = null),
                  ),
          ),
          const SizedBox(height: AppSpacing.xxxl),
          PrimaryButton(
            label: _isEditing ? 'Guardar' : 'Crear',
            onPressed: _submit,
            expand: true,
          ),
          if (_isEditing) ...[
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              onPressed: _delete,
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.error,
                minimumSize: const Size.fromHeight(52),
                side: BorderSide(color: colors.error.withValues(alpha: 0.5)),
              ),
              child: const Text('Eliminar cita'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Tile de fecha o de hora: etiqueta y valor. Comparte el aspecto de los campos
/// del formulario (canvas + borde hairline).
class _DateTimeTile extends StatelessWidget {
  const _DateTimeTile({
    required this.label,
    required this.value,
    required this.borderRadius,
    required this.onTap,
    this.trailing,
  });

  final String label;
  final String value;
  final BorderRadius borderRadius;
  final VoidCallback onTap;

  /// Acción al final de la tile (p. ej. quitar el valor), si la hay.
  final Widget? trailing;

  /// Borde de la tile: mismo trazo que los campos del formulario, con el radio
  /// que le toca según su posición en el par de tiles unidas.
  OutlineInputBorder _outline(
    Color color, {
    double width = AppStroke.hairline,
  }) {
    return OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide(color: color, width: width),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    // Sin wrapper que recorte: la etiqueta flotante sobresale del borde y
    // quedaría cortada por la mitad.
    return InkWell(
      onTap: onTap,
      borderRadius: borderRadius,
      child: InputDecorator(
        // Con contenido siempre: la etiqueta flota sobre el borde, igual que
        // en los demás campos del formulario.
        isEmpty: false,
        decoration: InputDecoration(
          labelText: label.toUpperCase(),
          filled: true,
          fillColor: colors.canvas,
          contentPadding: FieldStyle.padding,
          suffixIcon: trailing,
          labelStyle: AppTypography.bodySm.copyWith(color: colors.body),
          floatingLabelStyle: AppTypography.fieldLabel(colors.ink),
          border: _outline(colors.cardBorder),
          enabledBorder: _outline(colors.cardBorder),
          focusedBorder: _outline(colors.ink, width: AppStroke.focused),
        ),
        child: Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.bodyMd.copyWith(color: colors.ink),
        ),
      ),
    );
  }
}

/// Réplica de una fila de la lista de citas: muestra en vivo cómo quedará la
/// cita con el título, la ubicación y las notas introducidos.
class _AppointmentPreview extends StatelessWidget {
  const _AppointmentPreview({
    required this.titleCtrl,
    required this.descriptionCtrl,
    required this.locationCtrl,
    required this.dateTime,
    required this.use24H,
  });

  final TextEditingController titleCtrl;
  final TextEditingController descriptionCtrl;
  final TextEditingController locationCtrl;
  final DateTime dateTime;
  final bool use24H;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return ListenableBuilder(
      listenable: Listenable.merge([titleCtrl, descriptionCtrl, locationCtrl]),
      builder: (context, _) {
        final title = titleCtrl.text.trim();
        final location = locationCtrl.text.trim();
        final hasNotes = descriptionCtrl.text.trim().isNotEmpty;

        final timeText = formatClockTime(
          dateTime,
          use24HourFormat: use24H,
        );
        final periodText = formatClockPeriod(
          dateTime,
          use24HourFormat: use24H,
        );
        final timeStyle = AppTypography.displayMd.copyWith(
          color: colors.ink,
          height: 1,
        );

        return Container(
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            color: colors.canvas,
            borderRadius: AppRadius.brTile,
            border: Border.all(
              color: colors.cardBorder,
              width: AppStroke.hairline,
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 88,
                child: use24H
                    ? Center(
                        child: Text(
                          timeText,
                          style: timeStyle,
                          textAlign: TextAlign.center,
                          softWrap: false,
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            timeText,
                            style: timeStyle,
                            textAlign: TextAlign.center,
                            softWrap: false,
                          ),
                          Text(
                            periodText,
                            style: AppTypography.caption.copyWith(
                              color: colors.muted,
                              height: 1,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                            softWrap: false,
                          ),
                        ],
                      ),
              ),
              const SizedBox(width: AppSpacing.md),
              VerticalDivider(
                width: 1,
                thickness: 1,
                color: colors.cardBorder,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title.isEmpty ? 'Sin título' : title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMdStrong.copyWith(
                        color: title.isEmpty ? colors.muted : colors.ink,
                      ),
                    ),
                    if (location.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xxs),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: colors.muted,
                            ),
                            const SizedBox(width: AppSpacing.xxs),
                            Expanded(
                              child: Text(
                                location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodySm.copyWith(
                                  color: colors.muted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              if (hasNotes)
                Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.xs),
                  child: Icon(
                    Icons.notes_rounded,
                    size: 18,
                    color: colors.muted,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
