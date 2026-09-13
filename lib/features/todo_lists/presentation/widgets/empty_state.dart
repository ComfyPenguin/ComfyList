import 'package:flutter/material.dart';

import '../../../../shared/core/theme/app_spacing.dart';
import '../../../../shared/core/theme/app_theme.dart';
import '../../../../shared/core/theme/app_typography.dart';
import '../../../../shared/ui/cards/app_card.dart';

/// Empty state de la pantalla de listas — mismo patrón visual que el
/// empty state de todos (canvas-soft + radio xl).
class TodoListsEmptyState extends StatelessWidget {
  const TodoListsEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: AppCard(
          padding: const EdgeInsets.all(AppSpacing.xxxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.checklist_rounded, size: 56, color: colors.ink),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Sin listas',
                style: AppTypography.displayMd.copyWith(color: colors.ink),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Crea tu primera lista para organizar tus tareas.',
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
