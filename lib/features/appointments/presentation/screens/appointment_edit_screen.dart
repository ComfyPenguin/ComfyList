import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../shared/core/theme/app_spacing.dart';
import '../../../../shared/core/theme/app_theme.dart';
import '../../../../shared/core/theme/app_typography.dart';
import '../../../../shared/ui/buttons/primary_button.dart';
import '../../../../shared/ui/dialogs/confirm_action_dialog.dart';
import '../../../../shared/ui/inputs/app_text_field.dart';
import '../../../../shared/ui/inputs/field_notch.dart';
import '../../../../shared/ui/pickers/date_time_pickers.dart';
import '../../../../shared/ui/text/app_tag.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../settings/presentation/providers/settings_state.dart';
import '../../domain/entities/appointment.dart';
import '../providers/appointments_provider.dart';
import '../providers/appointments_state.dart';

/// Radio de las cards del formulario — espejo de las tiles de la app.
const double _cardRadius = 32;

/// Radio de las esquinas interiores y separación de dos tiles unidas.
const double _joinedRadius = 6;
const double _joinedGap = 2;

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
  DateTime _dateTime = DateTime.now();
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
      final appointment = s.items
          .where((a) => a.id == widget.id)
          .cast<Appointment?>()
          .firstWhere((e) => true, orElse: () => null);
      if (appointment != null) {
        _titleCtrl.text = appointment.title;
        _descCtrl.text = appointment.description ?? '';
        _locationCtrl.text = appointment.location ?? '';
        _dateTime = appointment.dateTime;
        _hydratedTitle = appointment.title;
        _hydrated = true;
      }
    }
  }

  /// Formato de hora según el ajuste del usuario, igual que las tiles.
  static bool _use24HourFormatFrom(SettingsState state) => switch (state) {
    SettingsData(:final settings) => settings.use24HourFormat,
    _ => false,
  };

  Future<void> _pickDateTime() async {
    final pickedDate = await showAppDatePicker(context, initialDate: _dateTime);
    if (pickedDate == null) return;

    if (!mounted) return;
    final pickedTime = await showAppTimePicker(
      context,
      initialTime: TimeOfDay.fromDateTime(_dateTime),
      use24HourFormat: _use24HourFormatFrom(ref.read(settingsProvider)),
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

    if (_isEditing) {
      await notifier.updateFields(
        id: widget.id!,
        title: title,
        description: desc.isEmpty ? null : desc,
        clearDescription: desc.isEmpty,
        location: loc.isEmpty ? null : loc,
        clearLocation: loc.isEmpty,
        dateTime: _dateTime,
      );
    } else {
      await notifier.create(
        title: title,
        description: desc.isEmpty ? null : desc,
        location: loc.isEmpty ? null : loc,
        dateTime: _dateTime,
      );
    }
    if (mounted) context.pop();
  }

  Future<void> _delete() async {
    if (!_isEditing) return;

    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    final confirmed = await ConfirmActionDialog.show(
      context,
      title: '¿Eliminar cita?',
      message:
          '«$_hydratedTitle» se eliminará permanentemente. '
          'Esta acción no se puede deshacer.',
      confirmLabel: 'Eliminar',
      destructive: true,
    );
    if (!confirmed) return;

    await ref.read(appointmentsProvider.notifier).delete(widget.id!);
    if (!mounted) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('Cita «$_hydratedTitle» eliminada.')),
      );
    router.pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appointmentsProvider);
    final colors = context.colors;
    _hydrateFromState(state);

    // El formato de hora sigue el ajuste del usuario, igual que las tiles.
    final use24H = _use24HourFormatFrom(ref.watch(settingsProvider));
    final dateText = DateFormat('EEEE, d MMMM yyyy', 'es_ES').format(_dateTime);
    final timeText = DateFormat(
      use24H ? 'HH:mm' : 'hh:mm a',
      'es_ES',
    ).format(_dateTime);

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
              icon: Icons.calendar_today_outlined,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(_cardRadius),
                bottom: Radius.circular(_joinedRadius),
              ),
              onTap: _pickDateTime,
            ),
          ),
          const SizedBox(height: _joinedGap),
          _DateTimeTile(
            label: 'Hora',
            value: timeText,
            icon: Icons.schedule_outlined,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(_joinedRadius),
              bottom: Radius.circular(_cardRadius),
            ),
            onTap: _pickDateTime,
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

/// Tile de fecha o de hora: etiqueta, valor e icono del selector. Comparte el
/// aspecto de los campos del formulario (canvas + borde hairline).
class _DateTimeTile extends StatelessWidget {
  const _DateTimeTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.borderRadius,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final BorderRadius borderRadius;
  final VoidCallback onTap;

  /// Borde de la tile: mismo trazo que los campos del formulario, con el radio
  /// que le toca según su posición en el par de tiles unidas.
  OutlineInputBorder _outline(
    Color color, {
    double width = FieldStyle.borderWidth,
  }) {
    return OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide(color: color, width: width),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = colors.canvas.computeLuminance() < 0.05;
    final borderColor = isDark
        ? colors.ink.withValues(alpha: 0.18)
        : colors.ink.withValues(alpha: 0.12);

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
          labelText: label,
          filled: true,
          fillColor: colors.canvas,
          contentPadding: FieldStyle.padding,
          labelStyle: AppTypography.bodySm.copyWith(color: colors.body),
          floatingLabelStyle: AppTypography.bodySmStrong.copyWith(
            color: colors.ink,
          ),
          suffixIcon: Icon(icon, size: 20, color: colors.muted),
          border: _outline(borderColor),
          enabledBorder: _outline(borderColor),
          focusedBorder: _outline(colors.ink, width: 1.5),
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
    final isDark = colors.canvas.computeLuminance() < 0.05;
    final borderColor = isDark
        ? colors.ink.withValues(alpha: 0.18)
        : colors.ink.withValues(alpha: 0.12);

    return ListenableBuilder(
      listenable: Listenable.merge([titleCtrl, descriptionCtrl, locationCtrl]),
      builder: (context, _) {
        final title = titleCtrl.text.trim();
        final location = locationCtrl.text.trim();
        final hasNotes = descriptionCtrl.text.trim().isNotEmpty;

        final timeText = DateFormat(
          use24H ? 'HH:mm' : 'hh:mm',
          'es_ES',
        ).format(dateTime);
        final periodText = use24H
            ? ''
            : DateFormat('a', 'es_ES')
                  .format(dateTime)
                  .toUpperCase()
                  .replaceAll(RegExp(r'\s+'), '')
                  .replaceAll('.', '');
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
            borderRadius: BorderRadius.circular(_cardRadius),
            border: Border.all(color: borderColor, width: 1.2),
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
                color: colors.ink.withValues(alpha: 0.12),
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
