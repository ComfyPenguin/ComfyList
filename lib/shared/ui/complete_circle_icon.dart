import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../core/theme/app_theme.dart';

/// Icono animado de círculo con check para la acción de completar.
///
/// Tiñe el trazo de `assets/lottie/complete-circle.json` con
/// [AppColors.onError] para heredar el contraste de los atajos: blanco
/// sobre superficies saturadas en light, oscuro sobre suaves en dark.
///
/// La animación se reproduce una sola vez por montaje del widget: el
/// padre lo desmonta al cerrar el swipe y lo remonta en cada gesto.
/// [speed] acelera la reproducción para que se vea completa incluso con
/// gestos rápidos (el Lottie dura ~4,7 s a velocidad 1).
class CompleteCircleIcon extends StatefulWidget {
  const CompleteCircleIcon({
    super.key,
    this.size = 32,
    this.speed = 3,
  });

  final double size;
  final double speed;

  @override
  State<CompleteCircleIcon> createState() => _CompleteCircleIconState();
}

class _CompleteCircleIconState extends State<CompleteCircleIcon>
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
    final tint = context.colors.onError;
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
              value: tint,
            ),
          ],
        ),
        onLoaded: (composition) {
          _controller.duration = Duration(
            microseconds:
                (composition.duration.inMicroseconds / widget.speed).round(),
          );
          _controller
            ..reset()
            ..forward();
        },
      ),
    );
  }
}