import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../shared/core/theme/app_radius.dart';
import '../../../../shared/core/theme/app_spacing.dart';
import '../../../../shared/core/theme/app_theme.dart';
import '../../../../shared/core/theme/app_typography.dart';
import '../../../../shared/ui/buttons/primary_button.dart';
import '../../../../shared/ui/inputs/app_text_field.dart';
import '../../domain/entities/appointment.dart';
import '../providers/appointments_provider.dart';
import '../providers/appointments_state.dart';

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
          .firstWhere(
            (e) => true,
            orElse: () => null,
          );
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

  Future<void> _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _dateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate == null) return;

    if (!mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dateTime),
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

    final colors = context.colors;
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar cita?'),
        content: Text(
          '«$_hydratedTitle» se eliminará permanentemente. Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: colors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

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

    final dateTimeText =
        DateFormat('EEEE, d MMMM yyyy · HH:mm', 'es_ES').format(_dateTime);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Editar cita' : 'Nueva cita',
          style: AppTypography.displaySm.copyWith(color: colors.ink),
        ),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Eliminar',
              onPressed: _delete,
            ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xxxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                controller: _titleCtrl,
                label: 'Título',
                hint: '¿Qué cita tienes?',
                autofocus: !_isEditing,
                textInputAction: TextInputAction.next,
                errorText: _titleError,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _descCtrl,
                label: 'Notas (opcional)',
                maxLines: 4,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _locationCtrl,
                label: 'Ubicación (opcional)',
                hint: '¿Dónde es la cita?',
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.md),
              InkWell(
                onTap: _pickDateTime,
                borderRadius: AppRadius.brMd,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Fecha y hora',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    dateTimeText,
                    style: AppTypography.bodyMd.copyWith(color: colors.ink),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),
              PrimaryButton(
                label: _isEditing ? 'Guardar' : 'Crear',
                onPressed: _submit,
                expand: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
