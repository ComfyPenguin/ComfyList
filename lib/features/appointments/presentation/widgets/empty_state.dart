import 'package:flutter/material.dart';

import '../../../../shared/core/theme/app_radius.dart';
import '../../../../shared/core/theme/app_spacing.dart';
import '../../../../shared/core/theme/app_theme.dart';
import '../../../../shared/core/theme/app_typography.dart';

/// `ex-empty-state-card` del DESIGN.md — canvas-soft + radio xl,
/// padding xxxl, ilustración / icono centrado.
class AppointmentsEmptyState extends StatelessWidget {
  const AppointmentsEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Container(
          decoration: BoxDecoration(
            color: colors.canvasSoft,
            borderRadius: AppRadius.brXl,
          ),
          padding: const EdgeInsets.all(AppSpacing.xxxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.event_available_outlined,
                size: 56,
                color: colors.ink,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Sin citas',
                style: AppTypography.displayMd.copyWith(color: colors.ink),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Pulsa el botón para crear tu primera cita.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMd.copyWith(color: colors.body),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
