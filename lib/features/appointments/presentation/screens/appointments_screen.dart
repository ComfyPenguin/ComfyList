import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

import '../../../../routing/routes.dart';
import '../../../../shared/core/theme/app_radius.dart';
import '../../../../shared/core/theme/app_spacing.dart';
import '../../../../shared/core/theme/app_theme.dart';
import '../../../../shared/core/theme/app_typography.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../settings/presentation/providers/settings_state.dart';
import '../../domain/entities/appointment.dart';
import '../providers/appointments_provider.dart';
import '../providers/appointments_state.dart';
import '../widgets/appointment_detail_sheet.dart';
import '../widgets/appointment_tile.dart';
import '../widgets/empty_state.dart';

/// Pantalla de lista de citas. El Scaffold, AppBar, FAB y BottomBar
/// viven en [AppShell].
class AppointmentsScreen extends ConsumerWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appointmentsProvider);
    return _buildBody(context, state);
  }

  Widget _buildBody(BuildContext context, AppointmentsState state) {
    final topOffset = MediaQuery.of(context).padding.top + 56 + AppSpacing.md;
    final bottomOffset =
        72 + AppSpacing.lg + MediaQuery.of(context).padding.bottom;

    return switch (state) {
      AppointmentsInitial() ||
      AppointmentsLoading() => const Center(child: CircularProgressIndicator()),
      AppointmentsError(:final failure) => Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xxxl).copyWith(top: topOffset),
          child: Text(
            failure.message,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMd.copyWith(color: context.colors.body),
          ),
        ),
      ),
      AppointmentsData(:final items) =>
        items.isEmpty
            ? Padding(
                padding: EdgeInsets.only(top: topOffset),
                child: const AppointmentsEmptyState(),
              )
            : _AppointmentsList(
                items: items,
                topPadding: topOffset,
                bottomPadding: bottomOffset,
              ),
    };
  }
}

class _AppointmentsList extends ConsumerStatefulWidget {
  const _AppointmentsList({
    required this.items,
    required this.topPadding,
    required this.bottomPadding,
  });

  final List<Appointment> items;
  final double topPadding;
  final double bottomPadding;

  @override
  ConsumerState<_AppointmentsList> createState() => _AppointmentsListState();
}

class _AppointmentsListState extends ConsumerState<_AppointmentsList> {
  final _tileRevealProgressByDate = <DateTime, Map<String, double>>{};

  ({double top, double bottom}) _effectiveSeparationFor({
    required DateTime date,
    required int tileIndex,
    required List<Appointment> appointments,
  }) {
    final tileProgress = _tileRevealProgressByDate[date];
    if (tileProgress == null || tileProgress.isEmpty) {
      return (top: 0.0, bottom: 0.0);
    }

    final myId = appointments[tileIndex].id;
    final myProgress = tileProgress[myId] ?? 0.0;

    final prevId = tileIndex > 0
        ? appointments[tileIndex - 1].id
        : null;
    final nextId = tileIndex < appointments.length - 1
        ? appointments[tileIndex + 1].id
        : null;
    final prevProgress =
        prevId != null ? (tileProgress[prevId] ?? 0.0) : 0.0;
    final nextProgress =
        nextId != null ? (tileProgress[nextId] ?? 0.0) : 0.0;

    final top = myProgress > prevProgress ? myProgress : prevProgress;
    final bottom = myProgress > nextProgress ? myProgress : nextProgress;

    return (top: top, bottom: bottom);
  }

  void _setTileRevealProgress({
    required DateTime date,
    required String appointmentId,
    required double progress,
  }) {
    final nextTileProgress = progress.clamp(0.0, 1.0).toDouble();
    final tileProgress = _tileRevealProgressByDate.putIfAbsent(
      date,
      () => <String, double>{},
    );

    if (nextTileProgress <= 0.001) {
      tileProgress.remove(appointmentId);
      if (tileProgress.isEmpty) {
        _tileRevealProgressByDate.remove(date);
      }
    } else {
      tileProgress[appointmentId] = nextTileProgress;
    }

    setState(() {});
  }

  void _removeStaleRevealProgress(
    DateTime date,
    List<Appointment> appointments,
  ) {
    final tileProgress = _tileRevealProgressByDate[date];
    if (tileProgress == null) return;

    final visibleIds = appointments
        .map((appointment) => appointment.id)
        .toSet();
    tileProgress.removeWhere((id, _) => !visibleIds.contains(id));
    if (tileProgress.isEmpty) {
      _tileRevealProgressByDate.remove(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(appointmentsProvider.notifier);
    final colors = context.colors;
    final dateHeaderStyle = AppTypography.caption.copyWith(
      color: Color.lerp(colors.muted, colors.body, 0.4),
      fontWeight: FontWeight.w700,
      letterSpacing: 0.6,
    );

    // Leer preferencia de completado en citas.
    final settingsState = ref.watch(settingsProvider);
    final completionEnabled = switch (settingsState) {
      SettingsData(:final settings) => settings.appointmentsCompletionEnabled,
      _ => false,
    };

    // Ordenar por fecha ascendente (más próximas primero).
    // Solo separar hechas al final si el completado está activado.
    final sorted = [...widget.items]
      ..sort((a, b) {
        if (completionEnabled && a.isDone != b.isDone) {
          return a.isDone ? 1 : -1;
        }
        return a.dateTime.compareTo(b.dateTime);
      });

    // Agrupar citas por día.
    final grouped = <DateTime, List<Appointment>>{};
    for (final appt in sorted) {
      final d = appt.dateTime;
      final dateOnly = DateTime(d.year, d.month, d.day);
      grouped.putIfAbsent(dateOnly, () => []).add(appt);
    }

    final sortedDates = grouped.keys.toList()..sort();
    final visibleDates = sortedDates.toSet();
    _tileRevealProgressByDate.removeWhere(
      (date, _) => !visibleDates.contains(date),
    );

    // Construir grupos de fecha: cabecera + tiles con radios/gaps animados.
    final listChildren = <Widget>[];
    for (var i = 0; i < sortedDates.length; i++) {
      final date = sortedDates[i];
      final appts = grouped[date]!;
      _removeStaleRevealProgress(date, appts);

      if (i > 0) {
        listChildren.add(const SizedBox(height: AppSpacing.md));
      }

      listChildren.add(
        _AppointmentGroup(
          dateLabel: _formatDateHeader(date),
          isToday: _isToday(date),
          dateHeaderStyle: dateHeaderStyle,
          appointments: appts,
          completionEnabled: completionEnabled,
          separationFor: (i) => _effectiveSeparationFor(
            date: date,
            tileIndex: i,
            appointments: appts,
          ),
          onToggle: (appt, value) => notifier.toggleDone(appt.id, value),
          onTap: (appt) => showAppointmentDetailSheet(context: context, id: appt.id),
          onEdit: (appt) => context.push(Routes.appointmentEdit(appt.id)),
          onDelete: (appt) async {
            await notifier.delete(appt.id);
            if (!context.mounted) return;
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(content: Text('Cita «${appt.title}» eliminada.')),
              );
          },
          onRevealProgressChanged: (appt, progress) {
            _setTileRevealProgress(
              date: date,
              appointmentId: appt.id,
              progress: progress,
            );
          },
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        widget.topPadding,
        AppSpacing.lg,
        widget.bottomPadding,
      ),
      children: listChildren,
    );
  }

  /// Formato de cabecera de fecha. Muestra "HOY" o "MAÑANA" cuando
  /// corresponde, y la fecha completa en otros casos.
  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    if (date == today) return 'CITAS DE HOY';
    if (date == tomorrow) return 'MAÑANA';

    return DateFormat('EEEE, d MMM', 'es_ES').format(date).toUpperCase();
  }

  /// Usado para diferenciar la cabecera de "hoy" (píldora negra) del resto (texto plano).
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return date == today;
  }
}

class _AppointmentGroup extends StatelessWidget {
  const _AppointmentGroup({
    required this.dateLabel,
    required this.isToday,
    required this.dateHeaderStyle,
    required this.appointments,
    required this.completionEnabled,
    required this.separationFor,
    required this.onToggle,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onRevealProgressChanged,
  });

  static const double _joinedGap = 2;

  final String dateLabel;
  final bool isToday;
  final TextStyle dateHeaderStyle;
  final List<Appointment> appointments;
  final bool completionEnabled;

  /// Progreso de separación por borde (top/bottom) para el tile en
  /// `appointments[i]`.
  final ({double top, double bottom}) Function(int tileIndex) separationFor;

  final void Function(Appointment appointment, bool value) onToggle;
  final void Function(Appointment appointment) onTap;
  final void Function(Appointment appointment) onEdit;
  final Future<void> Function(Appointment appointment) onDelete;
  final void Function(Appointment appointment, double progress)
  onRevealProgressChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final children = <Widget>[
      Padding(
        padding: const EdgeInsets.only(
          left: AppSpacing.xl,
          bottom: AppSpacing.md,
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: isToday
              ? _TodayPill(label: dateLabel, colors: colors)
              : Text(dateLabel, style: dateHeaderStyle),
        ),
      ),
    ];

    for (var i = 0; i < appointments.length; i++) {
      final appt = appointments[i];
      final edges = separationFor(i);
      children.add(
        AppointmentTile(
          key: ValueKey(appt.id),
          appointment: appt,
          completionEnabled: completionEnabled,
          groupIndex: i,
          groupSize: appointments.length,
          topSeparationProgress: edges.top,
          bottomSeparationProgress: edges.bottom,
          onToggle: (v) => onToggle(appt, v),
          onTap: () => onTap(appt),
          onEdit: () => onEdit(appt),
          onDelete: () => onDelete(appt),
          onRevealProgressChanged: (value) {
            onRevealProgressChanged(appt, value);
          },
        ),
      );

      if (i < appointments.length - 1) {
        children.add(const SizedBox(height: _joinedGap));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

/// Píldora de "HOY" para la cabecera del grupo de citas del día actual.
class _TodayPill extends StatelessWidget {
  const _TodayPill({required this.label, required this.colors});

  final String label;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final isDark = colors.canvas.computeLuminance() < 0.05;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: AppRadius.brPill,
        boxShadow: isDark
            ? [
                // Modo oscuro: glow luminoso doble alrededor del FAB blanco
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: Offset.zero,
                ),
                BoxShadow(
                  color: colors.shadowDark,
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : [
                // Modo claro: sombra oscura pronunciada
                BoxShadow(
                  color: colors.shadowDark,
                  blurRadius: 10,
                  offset: const Offset(2, 5),
                ),
              ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LivePulse(color: colors.onPrimary),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: colors.onPrimary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _LivePulse extends StatefulWidget {
  const _LivePulse({required this.color});

  final Color color;

  @override
  State<_LivePulse> createState() => _LivePulseState();
}

class _LivePulseState extends State<_LivePulse>
    with SingleTickerProviderStateMixin {
  static const double _size = 12;

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _size,
      height: _size,
      child: Lottie.asset(
        'assets/lottie/live-pulse.json',
        controller: _controller,
        fit: BoxFit.contain,
        repeat: true,
        onLoaded: (composition) {
          _controller
            ..duration = composition.duration
            ..repeat();
        },
        delegates: LottieDelegates(
          values: [
            ValueDelegate.color(
              const ['**', 'Fill 1'],
              value: widget.color,
            ),
          ],
        ),
      ),
    );
  }
}
