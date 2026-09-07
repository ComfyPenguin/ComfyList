import 'package:flutter/material.dart';

/// Gestos horizontales que ejecutan una acción directamente al soltar.
class SwipeActions extends StatefulWidget {
  const SwipeActions({
    super.key,
    required this.child,
    this.onSwipeRight,
    this.onSwipeLeft,
    this.onRevealProgressChanged,
  });

  final Widget child;
  final VoidCallback? onSwipeRight;
  final VoidCallback? onSwipeLeft;

  /// Progreso absoluto del gesto: 0 cerrado, 1 umbral de swipe alcanzado.
  final ValueChanged<double>? onRevealProgressChanged;

  @override
  State<SwipeActions> createState() => _SwipeActionsState();
}

class _SwipeActionsState extends State<SwipeActions>
    with SingleTickerProviderStateMixin {
  static const double _swipeRatio = 0.25;
  static const double _flingThreshold = 700;
  static const double _actionThreshold = 0.62;
  static const double _directionLockThreshold = 0.04;
  static const double _visibleThreshold = 0.01;

  late final AnimationController _ctrl;
  double _maxWidth = 0;
  double _lastNotifiedProgress = 0;
  int _gestureDirection = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      lowerBound: -1,
      upperBound: 1,
      value: 0,
    )..addListener(_notifyProgress);
  }

  @override
  void dispose() {
    _ctrl
      ..removeListener(_notifyProgress)
      ..dispose();
    super.dispose();
  }

  double get _swipeWidth => _maxWidth * _swipeRatio;
  double get _minValue => widget.onSwipeLeft == null ? 0 : -1;
  double get _maxValue => widget.onSwipeRight == null ? 0 : 1;

  void _notifyProgress() {
    final progress = _ctrl.value.abs().clamp(0.0, 1.0).toDouble();
    final isResting = progress == 0 || progress == 1;
    if ((progress - _lastNotifiedProgress).abs() < 0.01 && !isResting) {
      return;
    }
    _lastNotifiedProgress = progress;
    widget.onRevealProgressChanged?.call(progress);
  }

  int _directionFor(double value) {
    if (value > _visibleThreshold) return 1;
    if (value < -_visibleThreshold) return -1;
    return 0;
  }

  void _onDragStart(DragStartDetails details) {
    _ctrl.stop();
    _gestureDirection = _directionFor(_ctrl.value);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_swipeWidth == 0) return;

    final delta = details.primaryDelta ?? 0;
    final proposed = _ctrl.value + delta / _swipeWidth;
    if (_gestureDirection == 0 && proposed.abs() >= _directionLockThreshold) {
      _gestureDirection = proposed > 0 ? 1 : -1;
    }

    final next = switch (_gestureDirection) {
      1 => proposed.clamp(0.0, _maxValue),
      -1 => proposed.clamp(_minValue, 0.0),
      _ => proposed.clamp(_minValue, _maxValue),
    };
    _ctrl.value = next.toDouble();
  }

  void _onDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final direction = _directionFor(_ctrl.value);
    final rightTriggered =
        direction > 0 &&
        widget.onSwipeRight != null &&
        (_ctrl.value >= _actionThreshold || velocity > _flingThreshold);
    final leftTriggered =
        direction < 0 &&
        widget.onSwipeLeft != null &&
        (_ctrl.value.abs() >= _actionThreshold || velocity < -_flingThreshold);

    _gestureDirection = 0;
    _settleTo(0);

    if (rightTriggered) {
      widget.onSwipeRight!.call();
    } else if (leftTriggered) {
      widget.onSwipeLeft!.call();
    }
  }

  void _settleTo(double target) {
    _ctrl.animateTo(
      target,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _maxWidth = constraints.maxWidth;
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (context, child) => Transform.translate(
            offset: Offset(_ctrl.value * _swipeWidth, 0),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: _onDragStart,
              onHorizontalDragUpdate: _onDragUpdate,
              onHorizontalDragEnd: _onDragEnd,
              child: child,
            ),
          ),
          child: widget.child,
        );
      },
    );
  }
}
