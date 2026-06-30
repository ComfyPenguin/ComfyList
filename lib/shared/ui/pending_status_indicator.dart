import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../core/theme/app_theme.dart';

/// Indicador redondo animado de cita pendiente: usa la Lottie
/// `assets/lottie/pending-circle.json` y la tiñe con `colors.muted`.
class PendingStatusIndicator extends StatefulWidget {
  const PendingStatusIndicator({super.key, this.size = 32});

  final double size;

  @override
  State<PendingStatusIndicator> createState() =>
      _PendingStatusIndicatorState();
}

class _PendingStatusIndicatorState extends State<PendingStatusIndicator>
    with SingleTickerProviderStateMixin {
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
    final color = context.colors.muted;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Lottie.asset(
        'assets/lottie/pending-circle.json',
        controller: _controller,
        fit: BoxFit.contain,
        repeat: false,
        delegates: LottieDelegates(
          values: [
            ValueDelegate.color(
              const ['**', 'Stroke 1'],
              value: color,
            ),
          ],
        ),
        onLoaded: (composition) {
          _controller
            ..duration = composition.duration
            ..reset()
            ..forward();
        },
      ),
    );
  }
}
