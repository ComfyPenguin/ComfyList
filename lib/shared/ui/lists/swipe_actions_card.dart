import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../complete_circle_icon.dart';
import '../pending_circle_icon.dart';
import '../recycle_bin_icon.dart';
import 'swipe_actions.dart';

class SwipeActionsCard extends StatelessWidget {
  const SwipeActionsCard({
    super.key,
    required this.child,
    required this.onTap,
    required this.onDelete,
    this.onComplete,
    this.isDone = false,
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

  final Widget child;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  /// Acción de la zona izquierda (deslizar a la derecha): completar o
  /// desmarcar según [isDone].
  final VoidCallback? onComplete;

  /// Estado completado del item: la zona izquierda pasa a naranja con el
  /// icono de pendiente para desmarcar.
  final bool isDone;

  final int groupIndex;
  final int groupSize;
  final double topSeparationProgress;
  final double bottomSeparationProgress;
  final ValueChanged<double>? onRevealProgressChanged;

  static const double joinedRadius = 6;
  static const double outerRadius = 32;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = colors.canvas.computeLuminance() < 0.05;
    final borderColor = isDark
        ? colors.ink.withValues(alpha: 0.18)
        : colors.ink.withValues(alpha: 0.12);
    final cardRadius = _borderRadiusForPosition();
    final completeAction = onComplete;

    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: cardRadius),
      clipBehavior: Clip.none,
      child: SwipeActions(
        onSwipeRight: onComplete,
        onSwipeLeft: onDelete,
        onRevealProgressChanged: onRevealProgressChanged,
        backgroundOverlap: SwipeActionsCard.outerRadius,
        leftBackground: completeAction == null
            ? null
            : _ActionZone(
                color: isDone ? colors.warning : colors.success,
                foreground: colors.onError,
                borderRadius: cardRadius,
                side: _ZoneSide.left,
                contentPadding: EdgeInsets.only(
                  right: SwipeActionsCard.outerRadius,
                ),
                icon: isDone
                    ? const PendingCircleIcon()
                    : const CompleteCircleIcon(),
                label: isDone ? 'Desmarcar' : 'Completar',
              ),
        rightBackground: _ActionZone(
          color: colors.error,
          foreground: colors.onError,
          borderRadius: cardRadius,
          side: _ZoneSide.right,
          contentPadding: EdgeInsets.only(left: SwipeActionsCard.outerRadius),
          icon: const RecycleBinIcon(),
          label: 'Eliminar',
        ),
        child: Material(
          color: colors.canvas,
          shape: RoundedRectangleBorder(
            borderRadius: cardRadius,
            side: BorderSide(color: borderColor, width: 1.2),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 72),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.lg,
                ),
                child: IntrinsicHeight(child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }

  BorderRadius _borderRadiusForPosition() {
    final isFirst = groupIndex == 0;
    final isLast = groupIndex == groupSize - 1;
    final topProgress = topSeparationProgress.clamp(0.0, 1.0).toDouble();
    final bottomProgress = bottomSeparationProgress.clamp(0.0, 1.0).toDouble();
    final topRadius = lerpDouble(joinedRadius, outerRadius, topProgress)!;
    final bottomRadius = lerpDouble(joinedRadius, outerRadius, bottomProgress)!;

    return BorderRadius.only(
      topLeft: Radius.circular(isFirst ? outerRadius : topRadius),
      topRight: Radius.circular(isFirst ? outerRadius : topRadius),
      bottomLeft: Radius.circular(isLast ? outerRadius : bottomRadius),
      bottomRight: Radius.circular(isLast ? outerRadius : bottomRadius),
    );
  }
}

enum _ZoneSide { left, right }

/// Fondo de color que se revela bajo la card durante el swipe, con icono
/// y título que indican la acción que ejecutará el gesto.
class _ActionZone extends StatelessWidget {
  const _ActionZone({
    required this.color,
    required this.foreground,
    required this.side,
    required this.contentPadding,
    required this.icon,
    required this.label,
    this.borderRadius,
  });

  final Color color;
  final Color foreground;
  final _ZoneSide side;
  final EdgeInsetsGeometry contentPadding;
  final Widget icon;
  final String label;
  final BorderRadius? borderRadius;

  BorderRadius? get _outerBorderRadius {
    final radius = borderRadius;
    if (radius == null) return null;

    return switch (side) {
      _ZoneSide.left => BorderRadius.only(
        topLeft: radius.topLeft,
        bottomLeft: radius.bottomLeft,
      ),
      _ZoneSide.right => BorderRadius.only(
        topRight: radius.topRight,
        bottomRight: radius.bottomRight,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final outerBorderRadius = _outerBorderRadius;
    return Material(
      color: color,
      shape: outerBorderRadius == null
          ? null
          : RoundedRectangleBorder(borderRadius: outerBorderRadius),
      clipBehavior: outerBorderRadius == null ? Clip.none : Clip.antiAlias,
      child: Padding(
        padding: contentPadding,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon,
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}