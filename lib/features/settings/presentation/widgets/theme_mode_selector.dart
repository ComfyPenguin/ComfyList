import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/core/theme/app_radius.dart';
import '../../../../shared/core/theme/app_spacing.dart';
import '../../../../shared/core/theme/app_theme.dart';
import '../../../../shared/core/theme/app_typography.dart';
import '../providers/settings_provider.dart';
import '../providers/settings_state.dart';
import 'settings_tile.dart';

/// Selector de tema: control segmentado con las tres opciones repartidas a
/// partes iguales, centradas, y la pastilla del color primario deslizándose
/// hasta la elegida.
class ThemeModeSelector extends ConsumerWidget {
  const ThemeModeSelector({super.key, this.isFirst = true, this.isLast = true});

  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final notifier = ref.read(settingsProvider.notifier);
    // Sin preferencias leídas no sabemos qué modo está guardado: el control se
    // queda sin opción marcada y sin responder.
    final loadFailed = ref.watch(settingsProvider) is SettingsError;
    final selectedIndex = loadFailed
        ? -1
        : _ThemeSegmentedControl.options.indexWhere((o) => o.value == mode);

    return SettingsTile(
      icon: Icons.palette_outlined,
      title: 'Tema',
      enabled: !loadFailed,
      isFirst: isFirst,
      isLast: isLast,
      child: _ThemeSegmentedControl(
        selectedIndex: selectedIndex,
        enabled: !loadFailed,
        onSelected: (index) => notifier.setThemeMode(
          _ThemeSegmentedControl.options[index].value,
        ),
      ),
    );
  }
}

class _ThemeSegmentedControl extends StatelessWidget {
  const _ThemeSegmentedControl({
    required this.selectedIndex,
    required this.enabled,
    required this.onSelected,
  });

  static const List<({IconData icon, String label, ThemeMode value})> options = [
    (
      icon: Icons.brightness_auto_outlined,
      label: 'Sistema',
      value: ThemeMode.system,
    ),
    (icon: Icons.light_mode_outlined, label: 'Claro', value: ThemeMode.light),
    (icon: Icons.dark_mode_outlined, label: 'Oscuro', value: ThemeMode.dark),
  ];

  /// Solo la pastilla se desliza; es el gesto que explica el cambio.
  static const Duration _slide = Duration(milliseconds: 240);
  static const Curve _slideCurve = Curves.easeOutCubic;
  static const double _height = 44;

  /// Aire entre la pastilla y el borde del raíl.
  static const double _inset = 3;

  final int selectedIndex;
  final bool enabled;
  final ValueChanged<int> onSelected;

  /// El mismo glow del botón primario: en oscuro un halo de luz del propio
  /// color primario más una sombra profunda; en claro, una sombra proyectada.
  static List<BoxShadow> _pillGlow(AppColors colors) {
    if (colors.isDarkCanvas) {
      return [
        BoxShadow(
          color: colors.primary.withValues(alpha: 0.35),
          blurRadius: 14,
          offset: Offset.zero,
        ),
        BoxShadow(
          color: colors.shadowDark,
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ];
    }

    return [
      BoxShadow(
        color: colors.shadowDark,
        blurRadius: 10,
        offset: const Offset(2, 5),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      height: _height,
      decoration: BoxDecoration(
        color: colors.canvasSoft,
        borderRadius: AppRadius.brPill,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segment = (constraints.maxWidth - _inset * 2) / options.length;
          return Stack(
            fit: StackFit.expand,
            // El glow de la pastilla sale del raíl: sin recortar, como el del
            // botón primario sobre el fondo.
            clipBehavior: Clip.none,
            children: [
              if (selectedIndex >= 0)
                AnimatedPositioned(
                  duration: _slide,
                  curve: _slideCurve,
                  left: _inset + segment * selectedIndex,
                  top: _inset,
                  bottom: _inset,
                  width: segment,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: AppRadius.brPill,
                      boxShadow: _pillGlow(colors),
                    ),
                  ),
                ),
              Row(
                children: [
                  for (var i = 0; i < options.length; i++)
                    Expanded(
                      child: _ThemeOption(
                        icon: options[i].icon,
                        label: options[i].label,
                        selected: i == selectedIndex,
                        enabled: enabled,
                        onTap: () => onSelected(i),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  /// El color acompaña al deslizamiento: el texto pasa de tinta a `onPrimary`
  /// mientras la pastilla llega.
  static const Duration _colorFade = Duration(milliseconds: 220);

  final IconData icon;
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final idle = enabled ? colors.ink : colors.muted;

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.brPill,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onTap : null,
          // Sin onda ni resalte: la pastilla que se desliza ya es la respuesta
          // al toque, y el destello sobre el raíl ensuciaba el gesto.
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          focusColor: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: selected ? 1 : 0),
            duration: _colorFade,
            curve: Curves.easeOut,
            builder: (context, t, _) {
              final color = Color.lerp(idle, colors.onPrimary, t)!;
              return Center(
                // Con texto muy grande o pantallas estrechas el contenido se
                // encoge antes que desbordar el tercio que le toca.
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 16, color: color),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        label,
                        style: AppTypography.bodySmStrong.copyWith(color: color),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
