import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/core/theme/app_spacing.dart';
import '../../../../shared/core/theme/app_theme.dart';
import '../../../../shared/core/theme/app_typography.dart';
import '../widgets/appointments_completed_to_bottom_toggle.dart';
import '../widgets/appointments_completion_toggle.dart';
import '../widgets/completed_to_bottom_toggle.dart';
import '../widgets/hour_format_toggle.dart';
import '../widgets/invert_swipe_actions_toggle.dart';
import '../widgets/notifications_toggle.dart';
import '../widgets/theme_mode_selector.dart';
import '../widgets/today_on_top_toggle.dart';

/// Pantalla de ajustes. Pantalla independiente fuera del [AppShell].
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Volver',
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Ajustes',
          style: AppTypography.displaySm.copyWith(color: colors.ink),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.section,
          ),
          children: [
            Text(
              'Apariencia',
              style: AppTypography.displayMd.copyWith(color: colors.ink),
            ),
            const SizedBox(height: AppSpacing.md),
            const ThemeModeSelector(),
            const SizedBox(height: AppSpacing.xxxl),
            Text(
              'Gestos',
              style: AppTypography.displayMd.copyWith(color: colors.ink),
            ),
            const SizedBox(height: AppSpacing.md),
            const InvertSwipeActionsToggle(),
            const SizedBox(height: AppSpacing.xxxl),
            Text(
              'Avisos',
              style: AppTypography.displayMd.copyWith(color: colors.ink),
            ),
            const SizedBox(height: AppSpacing.md),
            const NotificationsToggle(),
            const SizedBox(height: AppSpacing.xxxl),
            Text(
              'Citas',
              style: AppTypography.displayMd.copyWith(color: colors.ink),
            ),
            const SizedBox(height: AppSpacing.md),
            const AppointmentsCompletionToggle(),
            const SizedBox(height: AppSpacing.md),
            const AppointmentsCompletedToBottomToggle(),
            const SizedBox(height: AppSpacing.md),
            const HourFormatToggle(),
            const SizedBox(height: AppSpacing.md),
            const TodayOnTopToggle(),
            const SizedBox(height: AppSpacing.xxxl),
            Text(
              'Tareas',
              style: AppTypography.displayMd.copyWith(color: colors.ink),
            ),
            const SizedBox(height: AppSpacing.md),
            const CompletedToBottomToggle(),
          ],
        ),
      ),
    );
  }
}
