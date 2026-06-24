import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../core/theme/app_theme.dart';

/// Icono animado de papelera de reciclaje para acciones destructivas.
///
/// El Lottie trae un gradiente verde-azulado hardcodeado en sus shapes.
/// Aplicamos un [ValueDelegate.gradientColor] que tiñe los 3 stops del
/// gradiente con [AppColors.onError] para que el icono herede el contraste
/// del tema: blanco sobre rojo vibrante en light, oscuro sobre rojo suave
/// en dark.
///
/// La animación se reproduce una sola vez por montaje del widget: el padre
/// cambia la [key] cada vez que quiere reiniciarla (p. ej. en cada reveal
/// del atajo de borrado). El [LottieController] interno ajusta la duración
/// a `composition.duration / speed` para acelerar la reproducción.
///
/// El Lottie tiene el contenido (cuerpo + tapa) en la mitad superior del
/// frame, así que en estado cerrado queda muy arriba dentro del botón.
/// [verticalOffset] desplaza el Lottie en Y para centrarlo visualmente
/// cuando la tapa está cerrada.
class RecycleBinIcon extends StatefulWidget {
  const RecycleBinIcon({
    super.key,
    this.size = 40,
    this.speed = 1.5,
    this.verticalOffset = -5,
  });

  final double size;
  final double speed;
  final double verticalOffset;

  @override
  State<RecycleBinIcon> createState() => _RecycleBinIconState();
}

class _RecycleBinIconState extends State<RecycleBinIcon>
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
      child: Transform.translate(
        offset: Offset(0, widget.verticalOffset),
        child: Lottie.asset(
          'assets/lottie/recycle-bin.json',
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
              ValueDelegate.gradientColor(
                const ['**', 'Group 1', 'Gradient Fill 1'],
                value: [tint, tint, tint],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
