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
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = colors.canvas.computeLuminance() < 0.05;

    final body = isLoading
        ? SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(colors.onPrimary),
            ),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: colors.onPrimary),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(
                label.toUpperCase(),
                style: AppTypography.buttonMd.copyWith(
                  color: colors.onPrimary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          );

    final box = Container(
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: AppRadius.brPill,
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.35),
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
