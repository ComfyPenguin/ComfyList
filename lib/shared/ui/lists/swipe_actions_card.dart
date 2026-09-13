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
    this.invertActions = false,
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

  /// Acción de completar o desmarcar según [isDone]. Sin invertir ocupa la
  /// zona izquierda (deslizar a la derecha); invertida, la derecha.
  final VoidCallback? onComplete;

  /// Estado completado del item: la zona de completar pasa a naranja con el
  /// icono de pendiente para desmarcar.
  final bool isDone;

  /// Si es `true`, las acciones se invierten: eliminar en la zona izquierda
  /// y completar en la derecha (por defecto es al revés).
  final bool invertActions;

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
    final cardRadius = _borderRadiusForPosition();
    final completeAction = onComplete;
    final completeOnLeft = !invertActions;

    // Zona de completar: verde (o naranja para desmarcar). Solo existe si la
    // acción de completar está disponible.
    Widget? completeZone(_ZoneSide side) {
      if (completeAction == null) return null;
      return _ActionZone(
        color: isDone ? colors.warning : colors.success,
        foreground: colors.onError,
        borderRadius: cardRadius,
        side: side,
        contentPadding: EdgeInsets.only(
          left: side == _ZoneSide.left ? 0 : SwipeActionsCard.outerRadius,
          right: side == _ZoneSide.left ? SwipeActionsCard.outerRadius : 0,
        ),
        icon: isDone ? const PendingCircleIcon() : const CompleteCircleIcon(),
        label: isDone ? 'Desmarcar' : 'Completar',
      );
    }

    // Zona de eliminar: siempre presente.
    Widget deleteZone(_ZoneSide side) {
      return _ActionZone(
        color: colors.error,
        foreground: colors.onError,
        borderRadius: cardRadius,
        side: side,
        contentPadding: EdgeInsets.only(
          left: side == _ZoneSide.left ? 0 : SwipeActionsCard.outerRadius,
          right: side == _ZoneSide.left ? SwipeActionsCard.outerRadius : 0,
        ),
        icon: const RecycleBinIcon(),
        label: 'Eliminar',
      );
    }

    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: cardRadius),
      clipBehavior: Clip.none,
      child: SwipeActions(
        onSwipeRight: completeOnLeft ? onComplete : onDelete,
        onSwipeLeft: completeOnLeft ? onDelete : onComplete,
        onRevealProgressChanged: onRevealProgressChanged,
        backgroundOverlap: SwipeActionsCard.outerRadius,
        leftBackground: completeOnLeft
            ? completeZone(_ZoneSide.left)
            : deleteZone(_ZoneSide.left),
        rightBackground: completeOnLeft
            ? deleteZone(_ZoneSide.right)
            : completeZone(_ZoneSide.right),
        child: Material(
          color: colors.canvas,
          shape: RoundedRectangleBorder(
            borderRadius: cardRadius,
            side: BorderSide(color: colors.cardBorder, width: 1.2),
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
