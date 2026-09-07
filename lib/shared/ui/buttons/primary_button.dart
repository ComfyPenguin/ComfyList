import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';

/// Canonical primary button: pill, primary background, onPrimary uppercase bold text, dual light/dark shadow.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expand = false,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool expand;

  /// Sobrescribe el fondo del pill (p. ej. [AppColors.error] en acciones destructivas).
  final Color? backgroundColor;

  /// Color de texto/icono sobre [backgroundColor].
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = colors.canvas.computeLuminance() < 0.05;

    final bg = backgroundColor ?? colors.primary;
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
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: bg.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: Offset.zero,
                ),
                BoxShadow(
                  color: colors.shadowDark,
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : [
                BoxShadow(
                  color: colors.shadowDark,
                  blurRadius: 10,
                  offset: const Offset(2, 5),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.brPill,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Center(child: body),
          ),
        ),
      ),
    );

    return expand
        ? SizedBox(width: double.infinity, child: box)
        : IntrinsicWidth(child: box);
  }
}
