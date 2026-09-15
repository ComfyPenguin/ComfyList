import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';

/// Pastilla del DS con un valor puesto: la etiqueta y, si se puede quitar, la ✕
/// al final.
///
/// El toque que quita es toda la pastilla, no solo la ✕: en un móvil el icono
/// solo es un blanco pequeño, y aquí quitarlo no rompe nada —se vuelve a añadir
/// en el menú—.
class AppChip extends StatelessWidget {
  const AppChip({super.key, required this.label, this.onDelete});

  final String label;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Semantics(
      button: onDelete != null,
      child: Material(
        color: colors.canvasSoft,
        borderRadius: AppRadius.brPill,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onDelete,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            // Una etiqueta larga en una fila estrecha encoge el contenido en
            // vez de desbordar la pastilla.
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: AppTypography.bodySmStrong.copyWith(
                      color: colors.ink,
                    ),
                  ),
                  if (onDelete != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Icon(Icons.close_rounded, size: 16, color: colors.muted),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
