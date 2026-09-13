import 'package:flutter/material.dart';

import '../../../../shared/core/theme/app_spacing.dart';
import '../../../../shared/core/theme/app_theme.dart';
import '../../../../shared/core/theme/app_typography.dart';
import '../../../../shared/ui/cards/app_card.dart';

/// Ajuste pendiente de implementación: fijar las citas de hoy arriba
/// en la pantalla de citas. Deshabilitado hasta que se implemente.
class TodayOnTopToggle extends StatelessWidget {
  const TodayOnTopToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Citas de hoy arriba',
                  style: AppTypography.bodyMdStrong.copyWith(color: colors.ink),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Mantiene las citas de hoy fijadas en la parte superior '
                  'de la lista de citas.',
                  style: AppTypography.bodySm.copyWith(color: colors.body),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Próximamente',
                  style: AppTypography.caption.copyWith(
                    color: colors.muted,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Switch.adaptive(value: false, onChanged: null),
        ],
      ),
    );
  }
}
