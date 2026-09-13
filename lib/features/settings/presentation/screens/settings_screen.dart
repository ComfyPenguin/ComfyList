import 'package:flutter/material.dart';

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

/// Pantalla de ajustes. Vive dentro del [AppShell], que pone el título y la
/// flecha atrás en su TopBar.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sectionStyle = AppTypography.sectionLabel(context.colors.muted);

    // El TopBar del shell se superpone al contenido: reservamos su altura
    // (iconButton + padding del AppBar) más un margen hasta la primera card.
    final topOffset = MediaQuery.paddingOf(context).top + 56 + AppSpacing.md;

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          topOffset,
          AppSpacing.lg,
          AppSpacing.section,
        ),
        children: [
          Text('APARIENCIA', style: sectionStyle),
          const SizedBox(height: AppSpacing.md),
          const ThemeModeSelector(),
          const SizedBox(height: AppSpacing.xxxl),
          Text('GESTOS', style: sectionStyle),
          const SizedBox(height: AppSpacing.md),
          const InvertSwipeActionsToggle(),
          const SizedBox(height: AppSpacing.xxxl),
          Text('AVISOS', style: sectionStyle),
          const SizedBox(height: AppSpacing.md),
          const NotificationsToggle(),
          const SizedBox(height: AppSpacing.xxxl),
          Text('CITAS', style: sectionStyle),
          const SizedBox(height: AppSpacing.md),
          const AppointmentsCompletionToggle(),
          const SizedBox(height: AppSpacing.md),
          const AppointmentsCompletedToBottomToggle(),
          const SizedBox(height: AppSpacing.md),
          const HourFormatToggle(),
          const SizedBox(height: AppSpacing.md),
          const TodayOnTopToggle(),
          const SizedBox(height: AppSpacing.xxxl),
          Text('TAREAS', style: sectionStyle),
          const SizedBox(height: AppSpacing.md),
          const CompletedToBottomToggle(),
        ],
      ),
    );
  }
}
