import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadow.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';

/// Canonical primary button: pill, primary background, onPrimary uppercase bold text, dual light/dark shadow.
///
/// Sin acción queda apagado en lugar de desaparecer: relleno `muted` y sin halo,
/// que el halo es lo que lo pone por delante del contenido.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expand = false,
    this.dense = false,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool expand;

  /// Versión compacta: menos relleno vertical, para el botón que vive dentro de
  /// un bloque de contenido en vez de ser la acción de la pantalla. Deja el alto
  /// en los 44 px del botón secundario.
  final bool dense;

  /// Sobrescribe el fondo del pill (p. ej. [AppColors.error] en acciones destructivas).
  final Color? backgroundColor;

  /// Color de texto/icono sobre [backgroundColor].
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final disabled = onPressed == null && !isLoading;
    final bg = backgroundColor ?? (disabled ? colors.muted : colors.primary);
    final fg = foregroundColor ?? colors.onPrimary;

    final body = isLoading
        ? SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(fg),
            ),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label.toUpperCase(),
                style: AppTypography.buttonMd.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
              if (icon != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Icon(icon, size: 18, color: fg),
              ],
            ],
          );

    final box = Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.brPill,
        boxShadow: disabled ? null : AppShadow.primaryGlow(colors, bg),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.brPill,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: dense ? AppSpacing.md : AppSpacing.lg,
            ),
            // `heightFactor: 1` para que en un alto acotado no se estire a lo
            // alto: la píldora mide lo que mide su contenido.
            child: Center(heightFactor: 1, child: body),
          ),
        ),
      ),
    );

    return expand
        ? SizedBox(width: double.infinity, child: box)
        : IntrinsicWidth(child: box);
  }
}
