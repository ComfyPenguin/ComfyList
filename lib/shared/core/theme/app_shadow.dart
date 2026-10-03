import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Sombras del sistema de diseño.
///
/// Los elementos primarios (botón, FAB, píldoras del contenido, pastilla del
/// segmentado) llevan un halo: en oscuro, un resplandor del propio color más
/// una sombra profunda; en claro, solo la sombra proyectada sobre el canvas.
class AppShadow {
  AppShadow._();

  /// Halo de los elementos primarios del tamaño de un contenido: botones,
  /// píldoras y controles. [color] es el relleno del elemento, por si va en un
  /// color que no es el primario.
  static List<BoxShadow> primaryGlow(AppColors colors, [Color? color]) {
    final glow = color ?? colors.primary;

    if (colors.isDarkCanvas) {
      return [
        BoxShadow(color: glow.withValues(alpha: 0.35), blurRadius: 14),
        BoxShadow(
          color: colors.shadowDark,
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ];
    }

    return [
      BoxShadow(
        color: colors.shadowDark,
        blurRadius: 10,
        offset: const Offset(2, 5),
      ),
    ];
  }

  /// Halo del FAB: el mismo criterio que [primaryGlow], más abierto y con la
  /// sombra desplazada, porque el botón es más grande y flota sobre el chrome.
  static List<BoxShadow> fabGlow(AppColors colors) {
    if (colors.isDarkCanvas) {
      return [
        BoxShadow(
          color: colors.primary.withValues(alpha: 0.35),
          blurRadius: 20,
        ),
        BoxShadow(
          color: colors.shadowDark,
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
    }

    return [
      BoxShadow(
        color: colors.shadowDark,
        blurRadius: 16,
        offset: const Offset(4, 8),
      ),
    ];
  }
}
