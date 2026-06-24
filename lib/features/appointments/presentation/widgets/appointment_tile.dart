import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../shared/core/theme/app_spacing.dart';
import '../../../../shared/core/theme/app_theme.dart';
import '../../../../shared/core/theme/app_typography.dart';
import '../../../../shared/ui/lists/swipe_reveal_actions.dart';
import '../../../../shared/ui/pencil_edit_icon.dart';
import '../../../../shared/ui/recycle_bin_icon.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../settings/presentation/providers/settings_state.dart';
import '../../domain/entities/appointment.dart';

/// Item de la lista de citas — sigue el diseño de Stitch:
/// columna izquierda con hora (HH:mm) yAM/PM, columna derecha con
/// título y descripción. Swipe a la derecha revela editar, swipe a la
/// izquierda revela borrar.
class AppointmentTile extends ConsumerStatefulWidget {
  const AppointmentTile({
    super.key,
    required this.appointment,
    required this.onToggle,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    this.completionEnabled = false,
    this.groupIndex = 0,
    this.groupSize = 1,
    this.topSeparationProgress = 1,
    this.bottomSeparationProgress = 1,
    this.onRevealProgressChanged,
  }) : assert(groupIndex >= 0),
       assert(groupSize > 0),
       assert(groupIndex < groupSize),
       assert(topSeparationProgress >= 0 && topSeparationProgress <= 1),
       assert(bottomSeparationProgress >= 0 && bottomSeparationProgress <= 1);

  final Appointment appointment;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool completionEnabled;

  /// Posición de la card dentro del grupo visual de un mismo día.
  final int groupIndex;

  /// Número total de cards dentro del grupo visual.
  final int groupSize;

  /// Separación del borde superior: 0 = pegado al vecino de arriba,
  /// 1 = despegado. Solo se aplica si no es el primer tile del grupo
  /// (en ese caso el borde es "outer" y siempre redondeado).
  final double topSeparationProgress;

  /// Separación del borde inferior: 0 = pegado al vecino de abajo,
  /// 1 = despegado. Solo se aplica si no es el último tile del grupo.
  final double bottomSeparationProgress;

  /// Progreso absoluto del swipe horizontal para revelar editar/borrar.
  final ValueChanged<double>? onRevealProgressChanged;

  static const double _joinedRadius = 6;
  static const double _outerRadius = 32;

  @override
  ConsumerState<AppointmentTile> createState() => _AppointmentTileState();
}

class _AppointmentTileState extends ConsumerState<AppointmentTile> {
  double _lastLeftReveal = 0;
  int _leftRevealCount = 0;
  double _lastRightReveal = 0;
  int _rightRevealCount = 0;

  void _onLeftReveal(double progress) {
    if (_lastLeftReveal < 0.6 && progress >= 0.6) {
      setState(() => _leftRevealCount++);
    }
    _lastLeftReveal = progress;
  }

  void _onRightReveal(double progress) {
    if (_lastRightReveal > -0.6 && progress <= -0.6) {
      setState(() => _rightRevealCount++);
    }
    _lastRightReveal = progress;
  }

  BorderRadius _borderRadiusForPosition() {
    final isFirst = widget.groupIndex == 0;
    final isLast = widget.groupIndex == widget.groupSize - 1;
    final tTop = widget.topSeparationProgress.clamp(0.0, 1.0).toDouble();
    final tBottom = widget.bottomSeparationProgress.clamp(0.0, 1.0).toDouble();
    final innerRadiusTop = lerpDouble(
      AppointmentTile._joinedRadius,
      AppointmentTile._outerRadius,
      tTop,
    )!;
    final innerRadiusBottom = lerpDouble(
      AppointmentTile._joinedRadius,
      AppointmentTile._outerRadius,
      tBottom,
    )!;

    return BorderRadius.only(
      topLeft: Radius.circular(
        isFirst ? AppointmentTile._outerRadius : innerRadiusTop,
      ),
      topRight: Radius.circular(
        isFirst ? AppointmentTile._outerRadius : innerRadiusTop,
      ),
      bottomLeft: Radius.circular(
        isLast ? AppointmentTile._outerRadius : innerRadiusBottom,
      ),
      bottomRight: Radius.circular(
        isLast ? AppointmentTile._outerRadius : innerRadiusBottom,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = colors.canvas.computeLuminance() < 0.05;
    final borderColor = isDark
        ? colors.ink.withValues(alpha: 0.18)
        : colors.ink.withValues(alpha: 0.12);
    final muted = colors.muted;
    final done = widget.completionEnabled && widget.appointment.isDone;
    final titleStyle = AppTypography.bodyMdStrong.copyWith(
      decoration: done ? TextDecoration.lineThrough : null,
      color: done ? muted : colors.ink,
    );
    final cardRadius = _borderRadiusForPosition();

    // Leer preferencia de formato 24H.
    final use24H = switch (ref.watch(settingsProvider)) {
      SettingsData(:final settings) => settings.use24HourFormat,
      _ => false,
    };

    // Hora y periodo según el formato elegido.
    final dateFmt = use24H ? 'HH:mm' : 'hh:mm';
    final timeText = DateFormat(dateFmt, 'es_ES').format(widget.appointment.dateTime);
    final periodText = use24H
        ? ''
        : DateFormat('a', 'es_ES')
              .format(widget.appointment.dateTime)
              .toUpperCase()
              .replaceAll(RegExp(r'\s+'), '')
              .replaceAll('.', '');
    final timeStyle = AppTypography.displayMd.copyWith(
      color: done ? muted : colors.ink,
      height: 1,
    );
    final periodStyle = AppTypography.caption.copyWith(
      color: muted,
      height: 1,
      fontWeight: FontWeight.w500,
    );

    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: cardRadius),
      clipBehavior: Clip.none,
      child: SwipeRevealActions(
        onRevealProgressChanged: widget.onRevealProgressChanged,
        onLeftRevealProgressChanged: _onLeftReveal,
        onRightRevealProgressChanged: _onRightReveal,
        actionOverlap: AppointmentTile._outerRadius,
        actionBorderRadius: cardRadius,
        leftAction: SwipeRevealAction(
          icon: PencilEditIcon(key: ValueKey(_leftRevealCount)),
          label: 'Editar cita',
          background: colors.surfacePressed,
          foreground: colors.ink,
          onTap: widget.onEdit,
        ),
        rightAction: SwipeRevealAction(
          icon: RecycleBinIcon(key: ValueKey(_rightRevealCount)),
          label: 'Eliminar cita',
          background: colors.error,
          foreground: colors.onError,
          onTap: widget.onDelete,
        ),
        child: Material(
          color: colors.canvas,
          shape: RoundedRectangleBorder(
            borderRadius: cardRadius,
            side: BorderSide(color: borderColor, width: 1.2),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 72),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.lg,
                ),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (widget.completionEnabled) ...[
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => widget.onToggle(!widget.appointment.isDone),
                          child: Checkbox(
                            value: widget.appointment.isDone,
                            onChanged: (v) => widget.onToggle(v ?? false),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.lg),
                      ],
                      // Columna izquierda: hora + periodo AM/PM (solo en 12H).
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
                                    style: periodStyle,
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
                        color: borderColor,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      // Columna derecha: título y ubicación si existe.
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(widget.appointment.title, style: titleStyle),
                            if (widget.appointment.location != null &&
                                widget.appointment.location!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: AppSpacing.xxs,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.location_on_outlined,
                                      size: 14,
                                      color: muted,
                                    ),
                                    const SizedBox(width: AppSpacing.xxs),
                                    Expanded(
                                      child: Text(
                                        widget.appointment.location!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.bodySm.copyWith(
                                          color: muted,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Icono de notas: centrado verticalmente, visible si hay notas.
                      if (widget.appointment.description != null &&
                          widget.appointment.description!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: AppSpacing.xs),
                          child: Icon(
                            Icons.notes_rounded,
                            size: 18,
                            color: muted,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
