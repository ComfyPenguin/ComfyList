import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_stroke.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';

/// Tokens de los campos card del DS (`AppTextField` con `cardStyle` y las tiles
/// de formulario).
class FieldStyle {
  FieldStyle._();

  /// Relleno interior del campo.
  static const EdgeInsets padding = EdgeInsets.symmetric(
    horizontal: AppSpacing.xl,
    vertical: 22,
  );
}

/// Escala final de la etiqueta flotante y margen del hueco que el framework
/// abre en el borde bajo ella (`InputDecorator`).
const double _labelScale = 0.75;
const double _gapPadding = 4;

/// Recorta el borde inferior de un campo bajo [label], la etiqueta flotante del
/// campo que va justo debajo.
///
/// `InputDecorator` solo abre el hueco en el borde superior del campo que lleva
/// la etiqueta. Al unir dos campos (misma separación y radios que las tiles de
/// la app) esa etiqueta se apoya sobre el borde de arriba, así que se recorta a
/// mano con la misma geometría para que los dos bordes queden cortados igual.
class BottomLabelNotch extends StatelessWidget {
  const BottomLabelNotch({
    super.key,
    required this.label,
    required this.child,
    this.fillColor,
  });

  /// Etiqueta flotante del campo contiguo inferior.
  final String label;

  final Widget child;

  /// Relleno del campo; por defecto el de los campos card del DS.
  final Color? fillColor;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      // La etiqueta flotante sobresale por encima de la card: sin recortes.
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          left: FieldStyle.padding.left,
          bottom: 0,
          width: _notchWidth(context, label),
          height: AppStroke.hairline + 1.5,
          child: IgnorePointer(
            child: ColoredBox(color: fillColor ?? context.colors.canvas),
          ),
        ),
      ],
    );
  }

  /// Anchura del hueco del framework: margen + etiqueta escalada + margen. Se
  /// mide la etiqueta ya en mayúsculas, con la tipografía de las etiquetas de
  /// campo y el escalado de texto del usuario.
  static double _notchWidth(BuildContext context, String label) {
    final painter = TextPainter(
      text: TextSpan(
        text: label.toUpperCase(),
        style: AppTypography.fieldLabel(),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    return painter.width * _labelScale + _gapPadding * 2;
  }
}
