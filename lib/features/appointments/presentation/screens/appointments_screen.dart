import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../routing/routes.dart';
import '../../../../shared/core/theme/app_spacing.dart';
import '../../../../shared/core/theme/app_theme.dart';
import '../../../../shared/core/theme/app_typography.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../settings/presentation/providers/settings_state.dart';
import '../../domain/entities/appointment.dart';
import '../providers/appointments_provider.dart';
import '../providers/appointments_state.dart';
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
    // Offset para no tapar el contenido bajo el AppBar anclado.
    final topOffset = MediaQuery.of(context).padding.top + 56 + AppSpacing.md;
    // Offset inferior: 72 (alto de la píldora del BottomBar) + margen + la
    // barra de navegación del sistema, para que el último tile no quede
    // tapado por el chrome inferior.
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

  /// Progreso de separación por borde (top/bottom) de un tile.
  /// - `top` se ve afectado por el progreso del propio tile y del vecino
  ///   ANTERIOR (si existe): si el vecino de arriba se desliza, este
  ///   borde debe redondearse.
  /// - `bottom` se ve afectado por el progreso del propio tile y del
  ///   vecino SIGUIENTE: si el vecino de abajo se desliza, este borde
  ///   debe redondearse.
  /// Así, al deslizar un tile solo se redondean las esquinas del tile
  /// movido y las que están pegadas a él en su(s) vecino(s).
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

    // El borde top del tile[i] se despega si se mueve el propio tile[i]
    // o el vecino anterior (tile[i-1]).
    final top = myProgress > prevProgress ? myProgress : prevProgress;
    // El borde bottom del tile[i] se despega si se mueve el propio
    // tile[i] o el vecino siguiente (tile[i+1]).
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

    // setState en cada callback (limitado por el dedup interno de
    // SwipeRevealActions, ~100 por reveal). Sin dedup aquí porque el
    // progreso del adyacente depende de la entrada del tile swipado
    // en el mapa, y cualquier cambio de ese mapa debe reflejarse en
    // el build para que el borde del vecino se actualice al instante.
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
          dateHeaderStyle: dateHeaderStyle,
          appointments: appts,
          completionEnabled: completionEnabled,
          separationFor: (i) => _effectiveSeparationFor(
            date: date,
            tileIndex: i,
            appointments: appts,
          ),
          onToggle: (appt, value) => notifier.toggleDone(appt.id, value),
          onTap: (appt) => context.push(Routes.appointmentDetail(appt.id)),
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

    if (date == today) return 'HOY';
    if (date == tomorrow) return 'MAÑANA';

    return DateFormat('EEEE, d MMM', 'es_ES').format(date).toUpperCase();
  }
}

class _AppointmentGroup extends StatelessWidget {
  const _AppointmentGroup({
    required this.dateLabel,
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
  final TextStyle dateHeaderStyle;
  final List<Appointment> appointments;
  final bool completionEnabled;

  /// Progreso de separación por borde (top/bottom) para el tile en
  /// `appointments[i]`. El `top` se ve afectado por el progreso del
  /// propio tile y del vecino ANTERIOR; el `bottom` por el del propio
  /// tile y del vecino SIGUIENTE. Así, al deslizar un tile solo se
  /// redondean las esquinas pegadas a él en su(s) vecino(s).
  final ({double top, double bottom}) Function(int tileIndex) separationFor;

  final void Function(Appointment appointment, bool value) onToggle;
  final void Function(Appointment appointment) onTap;
  final void Function(Appointment appointment) onEdit;
  final Future<void> Function(Appointment appointment) onDelete;
  final void Function(Appointment appointment, double progress)
  onRevealProgressChanged;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      Padding(
        padding: const EdgeInsets.only(
          left: AppSpacing.xl,
          bottom: AppSpacing.md,
        ),
        child: Text(dateLabel, style: dateHeaderStyle),
      ),
    ];

    for (var i = 0; i < appointments.length; i++) {
      final appt = appointments[i];
      final edges = separationFor(i);
      children.add(
        AppointmentTile(
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
