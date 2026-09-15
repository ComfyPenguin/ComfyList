import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';

/// Chip de selección del DS: pastilla `canvasSoft` que se enciende en primary
/// cuando está elegido.
///
/// Sin [onTap] no responde y el texto queda en `muted`: es el estado de las
/// opciones que ya no caben, con el límite de la fila alcanzado.
class AppFilterChip extends StatelessWidget {
  const AppFilterChip({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final enabled = onTap != null;

    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      child: Material(
        color: selected ? colors.primary : colors.canvasSoft,
        borderRadius: AppRadius.brPill,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Text(
              label,
              style: AppTypography.bodySmStrong.copyWith(
                color: switch ((selected, enabled)) {
                  (true, _) => colors.onPrimary,
                  (false, true) => colors.ink,
                  (false, false) => colors.muted,
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
