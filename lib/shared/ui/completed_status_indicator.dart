import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../core/theme/app_theme.dart';

/// Indicador redondo animado de cita completada: usa la Lottie
/// `assets/lottie/complete-circle.json` y la tiñe con `colors.primary`.
class CompletedStatusIndicator extends StatefulWidget {
  const CompletedStatusIndicator({super.key, this.size = 32});

  final double size;

  @override
  State<CompletedStatusIndicator> createState() =>
      _CompletedStatusIndicatorState();
}

class _CompletedStatusIndicatorState extends State<CompletedStatusIndicator>
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
    final color = context.colors.primary;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Lottie.asset(
        'assets/lottie/complete-circle.json',
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
