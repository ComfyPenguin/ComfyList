import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../routing/routes.dart';
import '../../../../shared/core/theme/app_spacing.dart';
import '../../../../shared/core/theme/app_theme.dart';
import '../../../../shared/core/theme/app_typography.dart';
import '../../../../shared/ui/buttons/app_primary_button.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../settings/presentation/providers/settings_state.dart';
import '../../domain/entities/appointment.dart';
import '../providers/appointments_provider.dart';
import '../providers/appointments_state.dart';

/// Pantalla de visualización de una cita (solo lectura). Muestra el título,
/// la fecha y hora, la descripción, el estado y las fechas de creación /
/// actualización. El botón de editar permite saltar a
/// [AppointmentEditScreen]; el tap en la AppBar navega hacia atrás.
class AppointmentDetailScreen extends ConsumerWidget {
  const AppointmentDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appointmentsProvider);
    final colors = context.colors;

    // Respetar la preferencia de completado en citas.
    final settingsState = ref.watch(settingsProvider);
    final completionEnabled = switch (settingsState) {
      SettingsData(:final settings) => settings.appointmentsCompletionEnabled,
      _ => false,
    };

    return switch (state) {
      AppointmentsInitial() || AppointmentsLoading() => Scaffold(
          appBar: AppBar(),
          body: const Center(child: CircularProgressIndicator()),
        ),
      AppointmentsError(:final failure) => Scaffold(
          appBar: AppBar(),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxxl),
              child: Text(
                failure.message,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMd.copyWith(color: colors.body),
              ),
            ),
          ),
        ),
      AppointmentsData(:final items) =>
          _buildDetail(context, items, colors, completionEnabled),
    };
  }

  Widget _buildDetail(
    BuildContext context,
    List<Appointment> items,
    AppColors colors,
    bool completionEnabled,
  ) {
    final appointment = items.cast<Appointment?>().firstWhere(
          (a) => a?.id == id,
          orElse: () => null,
        );

    // Si la cita no existe (p. ej. fue eliminada), mostramos un mensaje.
    if (appointment == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxxl),
            child: Text(
              'Cita no encontrada.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMd.copyWith(color: colors.body),
            ),
          ),
        ),
      );
    }

    final dateTimeFull = DateFormat(
      "EEEE, d 'de' MMMM 'de' yyyy '·' HH:mm",
      'es_ES',
    ).format(appointment.dateTime);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Detalles de la cita',
          style: AppTypography.displaySm.copyWith(color: colors.ink),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Editar',
            onPressed: () =>
                context.push(Routes.appointmentEdit(id)),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xxxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge de estado — solo visible si el completado está activo.
              if (completionEnabled) ...[
                _StatusBadge(isDone: appointment.isDone, colors: colors),
                const SizedBox(height: AppSpacing.lg),
              ],
              // Fecha y hora — lo más destacado de una cita.
              Row(
                children: [
                  Icon(Icons.event, size: 20, color: colors.muted),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      dateTimeFull,
                      style: AppTypography.bodyLg.copyWith(
                        color: colors.ink,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              // Título.
              Text(
                appointment.title,
                style: AppTypography.displayMd.copyWith(
                  color: colors.ink,
                  decoration: completionEnabled && appointment.isDone
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
              // Ubicación.
              if (appointment.location != null &&
                  appointment.location!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 20, color: colors.muted),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        appointment.location!,
                        style: AppTypography.bodyMd.copyWith(
                          color: colors.body,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              // Descripción.
              if (appointment.description != null &&
                  appointment.description!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Notas',
                  style: AppTypography.bodySmStrong.copyWith(
                    color: colors.muted,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  appointment.description!,
                  style: AppTypography.bodyMd.copyWith(color: colors.body),
                ),
              ],
              // Fechas de creación / actualización.
              const SizedBox(height: AppSpacing.xxxl),
              _MetaRow(
                label: 'Creada',
                value: _formatDate(appointment.createdAt),
                colors: colors,
              ),
              const SizedBox(height: AppSpacing.sm),
              _MetaRow(
                label: 'Actualizada',
                value: _formatDate(appointment.updatedAt),
                colors: colors,
              ),
              const SizedBox(height: AppSpacing.xxxl),
              // Botón de editar.
              AppPrimaryButton(
                label: 'Editar',
                onPressed: () =>
                    context.push(Routes.appointmentEdit(id)),
                expand: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Formatea una fecha en español: «15 may 2026, 18:30».
  static String _formatDate(DateTime dt) {
    const months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $h:$m';
  }
}

/// Badge pill que indica si la cita está completada o pendiente.
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isDone, required this.colors});

  final bool isDone;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: isDone
            ? colors.success.withValues(alpha: 0.1)
            : colors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        isDone ? 'Completada' : 'Pendiente',
        style: AppTypography.bodySmStrong.copyWith(
          color: isDone ? colors.success : colors.warning,
        ),
      ),
    );
  }
}

/// Fila de metadato: etiqueta en muted + valor en body.
class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.label,
    required this.value,
    required this.colors,
  });

  final String label;
  final String value;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: AppTypography.bodySm.copyWith(color: colors.muted),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTypography.bodySm.copyWith(color: colors.body),
          ),
        ),
      ],
    );
  }
}
