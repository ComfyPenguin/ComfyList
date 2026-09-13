import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_theme.dart';

/// Interruptor del DS: pastilla compacta con el thumb deslizando.
///
/// Sustituye al [Switch] de Material, que en M3 mide 52x32 y pesa demasiado en
/// una fila de ajustes. Encendido va en el color primario con el thumb en
/// `onPrimary`, como el botón primario; apagado, en `canvasSoft` con el thumb
/// en `canvas`.
class AppSwitch extends StatelessWidget {
  const AppSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
  });

  final bool value;

  /// `null` deja el interruptor deshabilitado (fondo apagado y sin respuesta).
  final ValueChanged<bool>? onChanged;

  final String? semanticLabel;

  static const double _width = 42;
  static const double _height = 24;
  static const double _thumb = 18;

  /// Aire entre el thumb y el borde del track.
  static const double _inset = 3;

  /// Área táctil mínima, sin agrandar la pastilla.
  static const double _tapHeight = 44;

  static const Duration _slide = Duration(milliseconds: 160);
  static const Curve _curve = Curves.easeOut;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final enabled = onChanged != null;
    final on = value;

    final track = AnimatedContainer(
      duration: _slide,
      curve: _curve,
      width: _width,
      height: _height,
      padding: const EdgeInsets.all(_inset),
      decoration: BoxDecoration(
        color: on ? colors.primary : colors.canvasSoft,
        borderRadius: AppRadius.brPill,
      ),
      child: AnimatedAlign(
        duration: _slide,
        curve: _curve,
        alignment: on ? Alignment.centerRight : Alignment.centerLeft,
        child: AnimatedContainer(
          duration: _slide,
          curve: _curve,
          width: _thumb,
          height: _thumb,
          decoration: BoxDecoration(
            color: on ? colors.onPrimary : colors.canvas,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );

    return Semantics(
      label: semanticLabel,
      checked: value,
      enabled: enabled,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: enabled ? () => onChanged!(!value) : null,
          child: SizedBox(
            width: _width,
            height: _tapHeight,
            child: Center(
              child: enabled ? track : Opacity(opacity: 0.45, child: track),
            ),
          ),
        ),
      ),
    );
  }
}
