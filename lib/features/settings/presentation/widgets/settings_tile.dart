import 'package:flutter/material.dart';

import '../../../../shared/core/theme/app_radius.dart';
import '../../../../shared/core/theme/app_spacing.dart';
import '../../../../shared/core/theme/app_stroke.dart';
import '../../../../shared/core/theme/app_theme.dart';
import '../../../../shared/core/theme/app_typography.dart';
import '../../domain/entities/app_settings.dart';
import '../providers/settings_state.dart';

/// Píldora de estado para las filas que aún no se pueden usar.
class SettingsTileBadge extends StatelessWidget {
  const SettingsTileBadge(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: colors.canvasSoft,
        borderRadius: AppRadius.brPill,
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          // Sobre el relleno de la píldora el `muted` se queda en ~2,3:1;
          // con el `body` sube a ~5,9:1 en claro y ~7,8:1 en oscuro.
          color: colors.body,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Indicador del hueco del switch mientras se leen las preferencias.
class SettingsTileSpinner extends StatelessWidget {
  const SettingsTileSpinner({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 24,
      height: 24,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }
}

/// Switch de una preferencia según el estado de lectura: con los datos guarda
/// su valor, mientras se leen muestra un indicador y si falla la lectura queda
/// deshabilitado. El aviso del fallo lo da el banner de la pantalla, una sola
/// vez, no cada fila.
class SettingsSwitch extends StatelessWidget {
  const SettingsSwitch({
    super.key,
    required this.state,
    required this.value,
    this.onChanged,
  });

  final SettingsState state;
  final bool Function(AppSettings settings) value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      SettingsData(:final settings) => Switch.adaptive(
        value: value(settings),
        onChanged: onChanged,
      ),
      SettingsError() => Switch.adaptive(value: false, onChanged: null),
      SettingsInitial() || SettingsLoading() => const SettingsTileSpinner(),
    };
  }
}

/// Fila de ajustes con el aspecto de las tiles de las listas: superficie
/// `canvas` con borde hairline y los radios que le tocan dentro de su grupo
/// ([isFirst]/[isLast]).
///
/// El icono va en un disco `canvasSoft`, el mismo relleno que las pills del
/// selector de tema.
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.trailing,
    this.child,
    this.enabled = true,
    this.isFirst = true,
    this.isLast = true,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;

  /// Control al final de la fila — el switch de la preferencia.
  final Widget? trailing;

  /// Contenido a lo ancho bajo el título, para las filas que no caben en una
  /// línea (el selector de tema).
  final Widget? child;

  final bool enabled;
  final bool isFirst;
  final bool isLast;
  final VoidCallback? onTap;

  static const double _iconDisc = 40;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = enabled ? colors.ink : colors.muted;

    final header = Row(
      children: [
        Container(
          width: _iconDisc,
          height: _iconDisc,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.canvasSoft,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: accent),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.bodyMdStrong.copyWith(color: accent),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                description,
                style: AppTypography.bodySm.copyWith(color: colors.body),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: AppSpacing.md),
          trailing!,
        ],
      ],
    );

    return Material(
      color: colors.canvas,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.joinedGroup(isFirst: isFirst, isLast: isLast),
        side: BorderSide(color: colors.cardBorder, width: AppStroke.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          child: child == null
              ? header
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    header,
                    const SizedBox(height: AppSpacing.lg),
                    child!,
                  ],
                ),
        ),
      ),
    );
  }
}
