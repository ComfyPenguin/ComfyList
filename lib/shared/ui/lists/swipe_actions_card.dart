import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import 'swipe_actions.dart';

class SwipeActionsCard extends StatelessWidget {
  const SwipeActionsCard({
    super.key,
    required this.child,
    required this.onTap,
    required this.onDelete,
    this.onComplete,
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
  final VoidCallback? onComplete;

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

    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: cardRadius),
      clipBehavior: Clip.none,
      child: SwipeActions(
        onSwipeRight: onComplete,
        onSwipeLeft: onDelete,
        onRevealProgressChanged: onRevealProgressChanged,
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
