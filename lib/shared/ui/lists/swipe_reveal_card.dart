import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import 'swipe_reveal_actions.dart';
import '../pencil_edit_icon.dart';
import '../recycle_bin_icon.dart';

class SwipeRevealCard extends StatefulWidget {
  const SwipeRevealCard({
    super.key,
    required this.child,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.editLabel,
    required this.deleteLabel,
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
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final String editLabel;
  final String deleteLabel;

  final int groupIndex;
  final int groupSize;
  final double topSeparationProgress;
  final double bottomSeparationProgress;
  final ValueChanged<double>? onRevealProgressChanged;

  static const double joinedRadius = 6;
  static const double outerRadius = 32;

  @override
  State<SwipeRevealCard> createState() => _SwipeRevealCardState();
}

class _SwipeRevealCardState extends State<SwipeRevealCard> {
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
    final topProgress = widget.topSeparationProgress.clamp(0.0, 1.0).toDouble();
    final bottomProgress = widget.bottomSeparationProgress
        .clamp(0.0, 1.0)
        .toDouble();
    final topRadius = lerpDouble(
      SwipeRevealCard.joinedRadius,
      SwipeRevealCard.outerRadius,
      topProgress,
    )!;
    final bottomRadius = lerpDouble(
      SwipeRevealCard.joinedRadius,
      SwipeRevealCard.outerRadius,
      bottomProgress,
    )!;

    return BorderRadius.only(
      topLeft: Radius.circular(
        isFirst ? SwipeRevealCard.outerRadius : topRadius,
      ),
      topRight: Radius.circular(
        isFirst ? SwipeRevealCard.outerRadius : topRadius,
      ),
      bottomLeft: Radius.circular(
        isLast ? SwipeRevealCard.outerRadius : bottomRadius,
      ),
      bottomRight: Radius.circular(
        isLast ? SwipeRevealCard.outerRadius : bottomRadius,
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
    final cardRadius = _borderRadiusForPosition();

    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: cardRadius),
      clipBehavior: Clip.none,
      child: SwipeRevealActions(
        onRevealProgressChanged: widget.onRevealProgressChanged,
        onLeftRevealProgressChanged: _onLeftReveal,
        onRightRevealProgressChanged: _onRightReveal,
        actionOverlap: SwipeRevealCard.outerRadius,
        actionBorderRadius: cardRadius,
        leftAction: SwipeRevealAction(
          icon: PencilEditIcon(key: ValueKey(_leftRevealCount)),
          label: widget.editLabel,
          background: colors.surfacePressed,
          foreground: colors.ink,
          onTap: widget.onEdit,
        ),
        rightAction: SwipeRevealAction(
          icon: RecycleBinIcon(key: ValueKey(_rightRevealCount)),
          label: widget.deleteLabel,
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
                child: IntrinsicHeight(child: widget.child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
