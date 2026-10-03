import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';

/// `card-content` del DESIGN.md — superficie `canvasSoft` con radio xl, sin
/// sombra ni borde (Level 0 flat). Es el bloque de los estados vacíos.
///
/// Las cards que van sobre el canvas con contorno y radio 32 son otra pieza
/// (`SwipeActionsCard` y las previews de los formularios).
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = _rowPadding,
  });

  /// Padding por defecto: el alto de una fila con switch.
  static const EdgeInsets _rowPadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.lg,
    vertical: AppSpacing.sm,
  );

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.canvasSoft,
        borderRadius: AppRadius.brXl,
      ),
      padding: padding,
      child: child,
    );
  }
}
