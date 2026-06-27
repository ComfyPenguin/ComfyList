import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../routing/routes.dart';
import '../../../../shared/core/theme/app_radius.dart';
import '../../../../shared/core/theme/app_spacing.dart';
import '../../../../shared/core/theme/app_theme.dart';
import '../../../../shared/core/theme/app_typography.dart';
import '../../../../shared/ui/buttons/app_primary_button.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../settings/presentation/providers/settings_state.dart';
import '../../domain/entities/appointment.dart';
import '../providers/appointments_provider.dart';
import '../providers/appointments_state.dart';

/// Muestra el bottom sheet de detalle de una cita (solo lectura).
Future<void> showAppointmentDetailSheet({
  required BuildContext context,
  required String id,
}) {
  return showModalBottomSheet<void>(
    context: context,
    // rootNavigator para que el sheet monte ENCIMA del shell (si no, el
    // BottomBar del AppShell queda visible por encima del sheet).
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) => AppointmentDetailSheet(
      id: id,
      // Pop con sheetContext, push con outerContext (no desmontado).
      onEdit: () {
        Navigator.of(sheetContext).pop();
        Future.microtask(() {
          if (!context.mounted) return;
          context.push(Routes.appointmentEdit(id));
        });
      },
    ),
  );
}

/// Bottom sheet que muestra los detalles de una cita (solo lectura).
///
/// Se presenta mediante `showAppointmentDetailSheet` desde la lista de
/// citas. Al pulsar «Editar» cierra el sheet y navega a la pantalla
/// de edición a través del callback [onEdit].
class AppointmentDetailSheet extends ConsumerWidget {
  const AppointmentDetailSheet({
    super.key,
    required this.id,
    required this.onEdit,
  });

  final String id;

  /// Callback que cierra el sheet y navega a la pantalla de edición.
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appointmentsProvider);
    final colors = context.colors;

    final settingsState = ref.watch(settingsProvider);
    final completionEnabled = switch (settingsState) {
      SettingsData(:final settings) => settings.appointmentsCompletionEnabled,
      _ => false,
    };

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: switch (state) {
        AppointmentsInitial() || AppointmentsLoading() =>
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
            child: Center(child: CircularProgressIndicator()),
          ),
        AppointmentsError(:final failure) => Padding(
            padding: const EdgeInsets.all(AppSpacing.xxxl),
            child: Center(
              child: Text(
                failure.message,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMd.copyWith(color: colors.body),
              ),
            ),
          ),
        AppointmentsData(:final items) => _buildContent(
            context,
            items,
            colors,
            completionEnabled,
          ),
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<Appointment> items,
    AppColors colors,
    bool completionEnabled,
  ) {
    final appointment = items.cast<Appointment?>().firstWhere(
          (a) => a?.id == id,
          orElse: () => null,
        );

    // Si la cita fue eliminada mientras el sheet estaba abierto.
    if (appointment == null) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Center(
          child: Text(
            'Cita no encontrada.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMd.copyWith(color: colors.body),
          ),
        ),
      );
    }

    String cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
    final isDark = colors.canvas.computeLuminance() < 0.05;

    final dt = appointment.dateTime;
    final dayName = cap(DateFormat("EEEE", 'es_ES').format(dt));
    final monthName = cap(DateFormat("MMMM", 'es_ES').format(dt));
    final dateFull = '$dayName, ${dt.day} de $monthName de ${dt.year}';
    final timeText = DateFormat('HH:mm').format(dt);

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sección de arriba: título, badge, fecha, hora, ubicación.
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xxxl,
              AppSpacing.sm,
              AppSpacing.xxxl,
              0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                if (completionEnabled) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _StatusBadge(isDone: appointment.isDone, colors: colors),
                ],
                const SizedBox(height: AppSpacing.lg),
                // Fecha.
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 20, color: colors.muted),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        dateFull,
                        style: AppTypography.bodyLg.copyWith(color: colors.ink),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                // Hora.
                Row(
                  children: [
                    Icon(Icons.access_time_outlined, size: 20, color: colors.muted),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        timeText,
                        style: AppTypography.bodyLg.copyWith(color: colors.ink),
                      ),
                    ),
                  ],
                ),
                if (appointment.location != null &&
                    appointment.location!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  // Ubicación.
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 20, color: colors.muted),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          appointment.location!,
                          style: AppTypography.bodyMd.copyWith(color: colors.body),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // Nota a ancho completo del sheet.
          if (appointment.description != null &&
              appointment.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xxxl,
                AppSpacing.xxxl,
                AppSpacing.xxxl,
                0,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  // surfacePressed en dark para elevación cromática.
                  color: isDark ? colors.surfacePressed : colors.canvasSoft,
                  borderRadius: AppRadius.brXl,
                  // Dark: halo claro (sombra oscura no se ve). Light: sombra M3.
                  boxShadow: isDark
                      ? [
                          BoxShadow(
                            color: colors.ink.withValues(alpha: 0.20),
                            blurRadius: 12,
                            spreadRadius: 1,
                          ),
                          BoxShadow(
                            color: colors.ink.withValues(alpha: 0.12),
                            blurRadius: 28,
                            spreadRadius: 2,
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: colors.shadowDark.withValues(alpha: 0.30),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                          BoxShadow(
                            color: colors.shadowDark.withValues(alpha: 0.18),
                            blurRadius: 28,
                            offset: const Offset(0, 0),
                          ),
                        ],
                ),
                child: Text(
                  appointment.description!,
                  style: AppTypography.bodyMd.copyWith(color: colors.body),
                ),
              ),
            ),
          // Sección de abajo: última edición + botón editar.
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xxxl,
              AppSpacing.xxxl,
              AppSpacing.xxxl,
              AppSpacing.xxxl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Última edición.
                _MetaRow(
                  label: 'Última edición',
                  value: _formatDate(appointment.updatedAt),
                  colors: colors,
                ),
                const SizedBox(height: AppSpacing.xxxl),
                AppPrimaryButton(
                  label: 'Editar',
                  onPressed: onEdit,
                  expand: true,
                ),
                SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Formatea una fecha en español: «18:30 · 15 may 2026».
  static String _formatDate(DateTime dt) {
    const months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m · ${dt.day} ${months[dt.month - 1]} ${dt.year}';
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
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTypography.bodySm.copyWith(color: colors.muted),
          ),
          const SizedBox(width: AppSpacing.lg),
          Text(
            value,
            style: AppTypography.bodySm.copyWith(color: colors.body),
          ),
        ],
      ),
    );
  }
}
