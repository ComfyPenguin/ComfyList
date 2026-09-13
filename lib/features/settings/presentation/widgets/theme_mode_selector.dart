import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/core/theme/app_radius.dart';
import '../../../../shared/core/theme/app_spacing.dart';
import '../../../../shared/core/theme/app_theme.dart';
import '../../../../shared/core/theme/app_typography.dart';
import '../providers/settings_provider.dart';
import '../providers/settings_state.dart';
import 'settings_tile.dart';

/// Selector de tema — pills horizontales (`category-button` / `pill-tab`):
/// activo en ink, inactivos en canvas-soft con texto ink.
class ThemeModeSelector extends ConsumerWidget {
  const ThemeModeSelector({super.key, this.isFirst = true, this.isLast = true});

  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final colors = context.colors;
    // Sin preferencias leídas no sabemos qué modo está guardado, así que no
    // marcamos ninguna pill y las dejamos sin poder pulsarse.
    final loadFailed = ref.watch(settingsProvider) is SettingsError;

    Widget pill({
      required IconData icon,
      required String label,
      required ThemeMode value,
    }) {
      final selected = !loadFailed && mode == value;
      final foreground = selected
          ? colors.onPrimary
          : (loadFailed ? colors.muted : colors.ink);
      return Padding(
        padding: const EdgeInsets.only(right: AppSpacing.sm),
        child: Material(
          color: selected ? colors.primary : colors.canvasSoft,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.brPill),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: loadFailed ? null : () => notifier.setThemeMode(value),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 18, color: foreground),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    label,
                    style: AppTypography.bodySmStrong.copyWith(
                      color: foreground,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return SettingsTile(
      icon: Icons.palette_outlined,
      title: 'Tema',
      description: 'Claro, oscuro o el que tenga el sistema.',
      enabled: !loadFailed,
      isFirst: isFirst,
      isLast: isLast,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            pill(
              icon: Icons.brightness_auto_outlined,
              label: 'Sistema',
              value: ThemeMode.system,
            ),
            pill(
              icon: Icons.light_mode_outlined,
              label: 'Claro',
              value: ThemeMode.light,
            ),
            pill(
              icon: Icons.dark_mode_outlined,
              label: 'Oscuro',
              value: ThemeMode.dark,
            ),
          ],
        ),
      ),
    );
  }
}
