import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../core/theme/app_theme.dart';

/// Icono animado de lápiz para acciones de edición.
///
/// El Lottie trae los fills del lápiz en negro hardcodeado y la línea
/// inferior con stroke negro + relleno blanco (que sirve de "erase"
/// sobre la superficie del botón). Aplicamos [ValueDelegate]s para:
///
/// - `Pen Outlines / ** / Fill 1` → `ink` (lápiz adopta el color de
///   texto del tema).
/// - `Slide Outlines / Group 1 / Stroke 1` → `ink` (línea inferior).
/// - `Slide Outlines / Group 2 / Fill 1` → `surfacePressed` (el
///   "erase" pasa a ser del color de la superficie del action, así
///   no se ve un rectángulo blanco).
///
/// La animación se reproduce una sola vez por montaje del widget: el
/// padre cambia la [key] cada vez que quiere reiniciarla. El
/// [AnimationController] interno ajusta la duración a
/// `composition.duration / speed` para acelerar la reproducción.
class PencilEditIcon extends StatefulWidget {
  const PencilEditIcon({
    super.key,
    this.size = 32,
    this.speed = 1.5,
    this.verticalOffset = -5,
  });

  final double size;
  final double speed;
  final double verticalOffset;

  @override
  State<PencilEditIcon> createState() => _PencilEditIconState();
}

class _PencilEditIconState extends State<PencilEditIcon>
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
    final colors = context.colors;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Transform.translate(
        offset: Offset(0, widget.verticalOffset),
        child: Lottie.asset(
          'assets/lottie/pencil-edit.json',
          controller: _controller,
          fit: BoxFit.contain,
          repeat: false,
          onLoaded: (composition) {
            _controller.duration = Duration(
              microseconds:
                  (composition.duration.inMicroseconds / widget.speed).round(),
            );
            _controller
              ..reset()
              ..forward();
          },
          delegates: LottieDelegates(
            values: [
              ValueDelegate.color(
                const ['Pen Outlines', '**', 'Fill 1'],
                value: colors.ink,
              ),
              ValueDelegate.strokeColor(
                const ['Slide Outlines', 'Group 1', 'Stroke 1'],
                value: colors.ink,
              ),
              ValueDelegate.color(
                const ['Slide Outlines', 'Group 2', 'Fill 1'],
                value: colors.surfacePressed,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
