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
///
/// Las preferencias de una misma sección forman un grupo de tiles unidos, con
/// la geometría de las listas: radios 32/6 y 2 px entre ellos.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sectionStyle = AppTypography.sectionLabel(context.colors.muted);

    // El TopBar del shell se superpone al contenido: reservamos su altura
    // (iconButton + padding del AppBar) más un margen hasta la primera sección.
    final topOffset = MediaQuery.paddingOf(context).top + 56 + AppSpacing.md;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        topOffset,
        AppSpacing.lg,
        AppSpacing.section,
      ),
      children: [
        _SectionHeader(label: 'APARIENCIA', style: sectionStyle),
        const ThemeModeSelector(),
        const SizedBox(height: AppSpacing.xxxl),
        _SectionHeader(label: 'GESTOS', style: sectionStyle),
        const InvertSwipeActionsToggle(),
        const SizedBox(height: AppSpacing.xxxl),
        _SectionHeader(label: 'AVISOS', style: sectionStyle),
        const NotificationsToggle(),
        const SizedBox(height: AppSpacing.xxxl),
        _SectionHeader(label: 'CITAS', style: sectionStyle),
        const AppointmentsCompletionToggle(isFirst: true, isLast: false),
        const SizedBox(height: AppSpacing.joined),
        const AppointmentsCompletedToBottomToggle(isFirst: false, isLast: false),
        const SizedBox(height: AppSpacing.joined),
        const HourFormatToggle(isFirst: false, isLast: false),
        const SizedBox(height: AppSpacing.joined),
        const TodayOnTopToggle(isFirst: false, isLast: true),
        const SizedBox(height: AppSpacing.xxxl),
        _SectionHeader(label: 'TAREAS', style: sectionStyle),
        const CompletedToBottomToggle(),
      ],
    );
  }
}

/// Cabecera de sección, sangrada igual que las cabeceras de grupo de las
/// listas de citas.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.style});

  final String label;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.xl,
        bottom: AppSpacing.md,
      ),
      child: Text(label, style: style),
    );
  }
}
