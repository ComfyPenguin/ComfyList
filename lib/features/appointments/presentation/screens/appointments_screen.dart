import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

import '../../../../shared/core/theme/app_radius.dart';
import '../../../../shared/core/theme/app_spacing.dart';
import '../../../../shared/core/theme/app_theme.dart';
import '../../../../shared/core/theme/app_typography.dart';
import '../../../../shared/ui/lists/slide_flow.dart';
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
  /// Tiempo que se mantiene el orden previo tras completar/desmarcar para
  /// que el tachado se reproduzca en el sitio donde se hizo el gesto.
  static const Duration _reorderDelay = Duration(milliseconds: 600);

  final _tileRevealProgressByDate = <DateTime, Map<String, double>>{};

  // Orden visual mostrado en el último build (ids), los items previos y si
  // se está retrasando el reordenado tras un cambio de isDone.
  List<String>? _displayedIds;
  List<Appointment>? _lastItems;
  bool _holdingReorder = false;
  Timer? _reorderTimer;

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

    final prevId = tileIndex > 0 ? appointments[tileIndex - 1].id : null;
    final nextId = tileIndex < appointments.length - 1
        ? appointments[tileIndex + 1].id
        : null;
    final prevProgress = prevId != null ? (tileProgress[prevId] ?? 0.0) : 0.0;
    final nextProgress = nextId != null ? (tileProgress[nextId] ?? 0.0) : 0.0;

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
  void dispose() {
    _reorderTimer?.cancel();
    super.dispose();
  }

  bool _sameIds(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Compara como conjunto (sin importar el orden del provider): solo nos
  /// importa que no haya altas/borrados para poder reordenar manteniendo
  /// los ids mostrados.
  bool _sameIdSet(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    final bSet = b.toSet();
    for (final id in a) {
      if (!bSet.contains(id)) return false;
    }
    return true;
  }

  /// Devuelve el orden a mostrar: si un único item acaba de cambiar de
  /// [Appointment.isDone] y eso reordenaría la lista, mantiene el orden
  /// anterior durante [_reorderDelay] para no cortar la animación del tachado.
  List<Appointment> _resolveDisplaySorted(List<Appointment> desired) {
    final items = widget.items;
    final currentIds = [for (final t in items) t.id];
    final previous = _lastItems;
    _lastItems = items;

    // Detectar si exactamente un item cambió de isDone desde el último build.
    String? toggledId;
    if (previous != null) {
      final prevById = {for (final t in previous) t.id: t};
      var flips = 0;
      for (final t in items) {
        final p = prevById[t.id];
        if (p != null && p.isDone != t.isDone) {
          toggledId = t.id;
          flips++;
        }
      }
      if (flips != 1) toggledId = null;
    }

    final canKeepLayout =
        _displayedIds != null && _sameIdSet(_displayedIds!, currentIds);
    final desiredIds = [for (final t in desired) t.id];
    final wouldReorder =
        toggledId != null &&
        canKeepLayout &&
        !_sameIds(_displayedIds!, desiredIds);

    if (wouldReorder && !_holdingReorder) {
      _holdingReorder = true;
      _reorderTimer?.cancel();
      _reorderTimer = Timer(_reorderDelay, () {
        if (!mounted) return;
        setState(() => _holdingReorder = false);
      });
    }

    if (_holdingReorder) {
      if (canKeepLayout) {
        final byId = {for (final t in items) t.id: t};
        return [for (final id in _displayedIds!) byId[id]!];
      }
      // El conjunto de ids cambió (alta/borrado): reordenar ya.
      _holdingReorder = false;
      _reorderTimer?.cancel();
      _reorderTimer = null;
    }

    _displayedIds = desiredIds;
    return desired;
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(appointmentsProvider.notifier);
    final colors = context.colors;
    final dateHeaderStyle = AppTypography.sectionLabel(
      Color.lerp(colors.muted, colors.body, 0.4),
    );

    // Leer preferencias de completado en citas.
    final settingsState = ref.watch(settingsProvider);
    final settings = switch (settingsState) {
      SettingsData(:final settings) => settings,
      _ => null,
    };
    final completionEnabled = settings?.appointmentsCompletionEnabled ?? false;
    // Si el ajuste está activado, las completadas van al final de su día.
    final completedToBottom = settings?.appointmentsCompletedToBottom ?? true;

    // Ordenar por fecha ascendente (más próximas primero).
    // Separar las completadas al final de su día solo con el ajuste activo.
    final sorted = [...widget.items]
      ..sort((a, b) {
        if (completionEnabled && completedToBottom && a.isDone != b.isDone) {
          return a.isDone ? 1 : -1;
        }
        return a.dateTime.compareTo(b.dateTime);
      });

    // Mantener el orden previo mientras se anima el tachado de un toggle.
    final displaySorted = _resolveDisplaySorted(sorted);

    // Agrupar citas por día.
    final grouped = <DateTime, List<Appointment>>{};
    for (final appt in displaySorted) {
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
          onTap: (appt) =>
              showAppointmentDetailSheet(context: context, id: appt.id),
          onComplete: (appt) => notifier.toggleDone(appt.id, !appt.isDone),
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
    required this.onTap,
    required this.onComplete,
    required this.onDelete,
    required this.onRevealProgressChanged,
  });

  /// Días con más citas que esto se renderizan en Column simple (sin
  /// deslizamiento) para no mantener todas las filas montadas.
  static const int _maxGlideTiles = 60;

  final String dateLabel;
  final bool isToday;
  final TextStyle dateHeaderStyle;
  final List<Appointment> appointments;
  final bool completionEnabled;

  /// Progreso de separación por borde (top/bottom) para el tile en
  /// `appointments[i]`.
  final ({double top, double bottom}) Function(int tileIndex) separationFor;

  final void Function(Appointment appointment) onTap;
  final void Function(Appointment appointment) onComplete;
  final Future<void> Function(Appointment appointment) onDelete;
  final void Function(Appointment appointment, double progress)
  onRevealProgressChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final header = Padding(
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
    );

    // Días con muchas citas: Column simple (sin animación de deslizamiento)
    // para no mantener todas las filas montadas.
    if (appointments.length > _maxGlideTiles) {
      final tiles = <Widget>[];
      for (var i = 0; i < appointments.length; i++) {
        tiles.add(_appointmentTile(i));
        if (i < appointments.length - 1) {
          tiles.add(const SizedBox(height: AppSpacing.joined));
        }
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [header, ...tiles],
      );
    }

    final rows = <SlideRow>[];
    for (var i = 0; i < appointments.length; i++) {
      rows.add(
        SlideRow(
          key: ValueKey(appointments[i].id),
          spacingAfter: i < appointments.length - 1 ? AppSpacing.joined : 0,
          child: _appointmentTile(i),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [header, SlideFlow(rows: rows)],
    );
  }

  Widget _appointmentTile(int index) {
    final appt = appointments[index];
    final edges = separationFor(index);
    return AppointmentTile(
      appointment: appt,
      completionEnabled: completionEnabled,
      groupIndex: index,
      groupSize: appointments.length,
      topSeparationProgress: edges.top,
      bottomSeparationProgress: edges.bottom,
      onTap: () => onTap(appt),
      onComplete: () => onComplete(appt),
      onDelete: () => onDelete(appt),
      onRevealProgressChanged: (value) {
        onRevealProgressChanged(appt, value);
      },
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
    final isDark = colors.isDarkCanvas;
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
            ValueDelegate.color(const ['**', 'Fill 1'], value: widget.color),
          ],
        ),
      ),
    );
  }
}
