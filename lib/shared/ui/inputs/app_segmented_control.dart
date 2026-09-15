import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadow.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_stroke.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';

/// Opción de un [AppSegmentedControl]: el valor que representa, su etiqueta y,
/// si la tiene, un icono delante.
@immutable
class AppSegmentOption<T> {
  const AppSegmentOption({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final IconData? icon;
}

/// Control segmentado del DS: raíl `canvasSoft` con la pastilla del color
/// primario deslizándose hasta la opción elegida. Las opciones se reparten a
/// partes iguales y cada una ocupa justo el hueco de la pastilla.
///
/// [selectedIndex] admite `-1` para cuando no sabemos qué valor está guardado:
/// el raíl se queda sin pastilla y el control no responde.
class AppSegmentedControl<T> extends StatelessWidget {
  const AppSegmentedControl({
    super.key,
    required this.options,
    required this.selectedIndex,
    required this.onSelected,
    this.enabled = true,
  });

  static const double _height = 44;

  /// Aire entre la pastilla y el borde del raíl. El contenido se sangra con el
  /// mismo valor para que cada opción ocupe justo la pastilla que le toca.
  static const double _inset = AppSpacing.xxs;

  /// Solo la pastilla se desliza; es el gesto que explica el cambio. El color
  /// del texto tarda lo mismo, así que llegan juntos.
  static const Duration _slide = Duration(milliseconds: 240);
  static const Curve _slideCurve = Curves.easeOutCubic;

  final List<AppSegmentOption<T>> options;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      height: _height,
      decoration: BoxDecoration(
        color: colors.canvasSoft,
        borderRadius: AppRadius.brPill,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segment = (constraints.maxWidth - _inset * 2) / options.length;
          return Stack(
            fit: StackFit.expand,
            // El halo de la pastilla sale del raíl: sin recortar, como el del
            // botón primario sobre el fondo.
            clipBehavior: Clip.none,
            children: [
              if (selectedIndex >= 0)
                AnimatedPositioned(
                  duration: _slide,
                  curve: _slideCurve,
                  left: _inset + segment * selectedIndex,
                  top: _inset,
                  bottom: _inset,
                  width: segment,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: AppRadius.brPill,
                      boxShadow: AppShadow.primaryGlow(colors),
                    ),
                  ),
                ),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(_inset),
                  child: Row(
                    children: [
                      for (var i = 0; i < options.length; i++)
                        Expanded(
                          child: _Segment(
                            option: options[i],
                            selected: i == selectedIndex,
                            enabled: enabled,
                            onTap: () => onSelected(i),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Segment<T> extends StatefulWidget {
  const _Segment({
    required this.option,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final AppSegmentOption<T> option;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  State<_Segment<T>> createState() => _SegmentState<T>();
}

class _SegmentState<T> extends State<_Segment<T>> {
  static const double _iconSize = 18;

  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final idle = widget.enabled ? colors.ink : colors.muted;
    // El anillo de foco va por delante: sobre la pastilla primaria el `ink` se
    // perdería, así que usa el color con el que se escribe encima.
    final ring = widget.selected ? colors.onPrimary : colors.ink;
    final icon = widget.option.icon;

    return Semantics(
      button: true,
      selected: widget.selected,
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.brPill,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.enabled ? widget.onTap : null,
          onFocusChange: (focused) => setState(() => _focused = focused),
          // Sin onda ni resalte: la pastilla que se desliza ya es la respuesta
          // al toque, y el destello sobre el raíl ensuciaba el gesto.
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          focusColor: Colors.transparent,
          child: Container(
            foregroundDecoration: !_focused
                ? null
                : BoxDecoration(
                    borderRadius: AppRadius.brPill,
                    border: Border.all(color: ring, width: AppStroke.focused),
                  ),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: widget.selected ? 1 : 0),
              duration: AppSegmentedControl._slide,
              curve: AppSegmentedControl._slideCurve,
              builder: (context, t, _) {
                final color = Color.lerp(idle, colors.onPrimary, t)!;
                return Center(
                  // Con texto muy grande o pantallas estrechas el contenido se
                  // encoge antes que desbordar el tercio que le toca.
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, size: _iconSize, color: color),
                          const SizedBox(width: AppSpacing.sm),
                        ],
                        Text(
                          widget.option.label,
                          style: AppTypography.bodySmStrong.copyWith(
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
