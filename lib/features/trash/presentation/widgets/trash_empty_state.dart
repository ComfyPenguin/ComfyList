import 'package:flutter/material.dart';

import '../../../../shared/core/theme/app_spacing.dart';
import '../../../../shared/core/theme/app_theme.dart';
import '../../../../shared/core/theme/app_typography.dart';
import '../../../../shared/ui/cards/app_card.dart';

/// Empty state de la papelera — mismo patrón visual que los de las listas
/// (canvas-soft + radio xl).
class TrashEmptyState extends StatelessWidget {
  const TrashEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.section),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.restore_from_trash_outlined, size: 56, color: colors.ink),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Papelera vacía',
              style: AppTypography.displayMd.copyWith(color: colors.ink),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Lo que borres se queda aquí, en este dispositivo, para poder '
              'recuperarlo.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMd.copyWith(color: colors.body),
            ),
          ],
        ),
      ),
    );
  }
}
