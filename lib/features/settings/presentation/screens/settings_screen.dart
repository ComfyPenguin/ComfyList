import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/core/theme/app_radius.dart';
import '../../../../shared/core/theme/app_spacing.dart';
import '../../../../shared/core/theme/app_stroke.dart';
import '../../../../shared/core/theme/app_theme.dart';
import '../../../../shared/core/theme/app_typography.dart';
import '../../../../shared/ui/animations/unfold_down.dart';
import '../providers/settings_provider.dart';
import '../providers/settings_state.dart';
import '../widgets/appointments_completed_to_bottom_toggle.dart';
import '../widgets/appointments_completion_toggle.dart';
import '../widgets/completed_to_bottom_toggle.dart';
import '../widgets/hour_format_selector.dart';
import '../widgets/invert_swipe_actions_toggle.dart';
import '../widgets/notifications_toggle.dart';
import '../widgets/theme_mode_selector.dart';
import '../widgets/today_on_top_toggle.dart';

/// Pantalla de ajustes. Vive dentro del [AppShell], que pone el título y la
/// flecha atrás en su TopBar.
///
/// Los ajustes generales van arriba sin cabecera; citas y tareas llevan tag de
/// sección porque agrupan varias preferencias de su feature. Cada grupo usa la
/// geometría de las listas: radios 32/6 y 2 px entre las tiles.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sectionStyle = AppTypography.sectionLabel(context.colors.muted);

    // El TopBar del shell se superpone al contenido: reservamos su altura
    // (iconButton + padding del AppBar) más un margen hasta la primera sección.
    final topOffset = MediaQuery.paddingOf(context).top + 56 + AppSpacing.md;

    final state = ref.watch(settingsProvider);
    final loadFailed = state is SettingsError;
    // Mientras no sepamos el valor, `null`: el bloque no se monta, así que al
    // llegar las preferencias la fila aparece de golpe con el resto de la
    // pantalla —no es una acción del usuario— y solo se despliega cuando se
    // enciende el ajuste del que cuelga ([UnfoldDown] no anima su primer
    // build).
    final completionEnabled = switch (state) {
      SettingsData(:final settings) => settings.appointmentsCompletionEnabled,
      _ => null,
    };

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        topOffset,
        AppSpacing.lg,
        AppSpacing.section,
      ),
      children: [
        if (loadFailed) ...[
          const _LoadErrorBanner(),
          const SizedBox(height: AppSpacing.xxxl),
        ],
        const ThemeModeSelector(isFirst: true, isLast: false),
        const SizedBox(height: AppSpacing.joined),
        const InvertSwipeActionsToggle(isFirst: false, isLast: false),
        const SizedBox(height: AppSpacing.joined),
        const NotificationsToggle(isFirst: false, isLast: true),
        const SizedBox(height: AppSpacing.xxxl),
        _SectionHeader(label: 'CITAS', style: sectionStyle),
        const HourFormatSelector(isFirst: true, isLast: false),
        const SizedBox(height: AppSpacing.joined),
        const AppointmentsCompletionToggle(isFirst: false, isLast: false),
        if (completionEnabled != null)
          UnfoldDown(
            open: completionEnabled,
            // La junta va dentro del bloque para que también abra con él.
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: AppSpacing.joined),
                AppointmentsCompletedToBottomToggle(
                  isFirst: false,
                  isLast: false,
                ),
              ],
            ),
          ),
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

/// Aviso de que no se han podido leer las preferencias: se muestra una sola
/// vez, sobre las secciones, mientras las filas quedan sin poder cambiarse.
///
/// El reintento relanza la lectura y, al pasar el estado a carga, este aviso
/// desaparece por sí solo con las filas mostrando su indicador.
class _LoadErrorBanner extends ConsumerWidget {
  const _LoadErrorBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: colors.canvas,
        borderRadius: AppRadius.brXl,
        border: Border.all(
          color: colors.error.withValues(alpha: 0.5),
          width: AppStroke.hairline,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, size: 20, color: colors.error),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'No se han podido leer tus ajustes.',
              style: AppTypography.bodySm.copyWith(color: colors.ink),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          TextButton(
            onPressed: () => ref.read(settingsProvider.notifier).reload(),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
