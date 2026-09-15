import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/core/theme/app_radius.dart';
import '../../../../shared/core/theme/app_spacing.dart';
import '../../../../shared/core/theme/app_stroke.dart';
import '../../../../shared/core/theme/app_theme.dart';
import '../../../../shared/core/theme/app_typography.dart';
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
    // pantalla —no es una acción del usuario— y solo se desliza cuando se
    // enciende el ajuste del que cuelga.
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
          _UnfoldDown(
            visible: completionEnabled,
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

/// Despliega su contenido hacia abajo: el hueco se abre justo debajo de la
/// fila de la que cuelga y el contenido se descubre desde su borde superior,
/// mientras las filas de abajo bajan lo que crece. Con el ajuste apagado el
/// bloque se cierra y la fila se esconde por el mismo sitio.
///
/// No anima en su primer build: cuando se monta ya trae su valor y lo aplica
/// tal cual, con el resto de la pantalla.
class _UnfoldDown extends StatefulWidget {
  const _UnfoldDown({required this.visible, required this.child});

  final bool visible;
  final Widget child;

  @override
  State<_UnfoldDown> createState() => _UnfoldDownState();
}

class _UnfoldDownState extends State<_UnfoldDown>
    with SingleTickerProviderStateMixin {
  static const Duration _duration = Duration(milliseconds: 260);

  late final AnimationController _controller = AnimationController(
    duration: _duration,
    vsync: this,
    value: widget.visible ? 1 : 0,
  );

  late final Animation<double> _reveal = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );

  @override
  void didUpdateWidget(covariant _UnfoldDown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible == oldWidget.visible) return;
    widget.visible ? _controller.forward() : _controller.reverse();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: _reveal,
      // Anclado arriba: el hueco crece hacia abajo y el contenido se descubre
      // desde arriba. El contenido no se desplaza — si lo hiciera, asomaría
      // primero su borde de abajo, que es el que no se ve venir.
      alignment: Alignment.topCenter,
      // Recogida no se pulsa ni se anuncia: solo queda el hueco, que es cero.
      child: ExcludeSemantics(
        excluding: !widget.visible,
        child: IgnorePointer(ignoring: !widget.visible, child: widget.child),
      ),
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
