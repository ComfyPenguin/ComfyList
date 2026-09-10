import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';

/// Pestañas disponibles en [AppBottomBar].
enum AppBottomTab { tasks, appointments }

/// Barra inferior flotante con glassmorphism (igual que el AppBar).
///
/// La píldora usa efecto cristal esmerilado con blur + fondo semi-transparente.
/// El FAB mantiene su estilo neumórfico (sombra/glow según tema).
///
/// Cuando [visible] es falso, la barra se desliza hacia abajo y colapsa.
class AppBottomBar extends StatelessWidget {
  const AppBottomBar({
    super.key,
    required this.activeTab,
    required this.onTasksTap,
    required this.onAppointmentsTap,
    this.onFabTap,
    this.fabTooltip,
    this.visible = true,
  });

  final AppBottomTab activeTab;
  final VoidCallback onTasksTap;
  final VoidCallback onAppointmentsTap;

  /// Callback del FAB central.
  final VoidCallback? onFabTap;
  final String? fabTooltip;

  /// Cuando es falso, la barra se desliza hacia abajo y colapsa.
  final bool visible;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // `padding.bottom` se reduce mientras el teclado está visible. Usar
    // `viewPadding` conserva el safe area real del dispositivo y evita que el
    // dock cambie de altura/posición al abrir o cerrar el teclado.
    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom;
    // Altura: píldora (72) + margen inferior (16) + safe area
    final totalHeight = 72.0 + AppSpacing.lg + bottomPadding;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      height: visible ? totalHeight : 0,
      clipBehavior: Clip.none,
      decoration: const BoxDecoration(),
      child: OverflowBox(
        minHeight: totalHeight,
        maxHeight: totalHeight,
        alignment: Alignment.bottomCenter,
        child: AnimatedSlide(
          offset: visible ? Offset.zero : const Offset(0, 1),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          child: AnimatedOpacity(
            opacity: visible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _BarContent(
              activeTab: activeTab,
              onTasksTap: onTasksTap,
              onAppointmentsTap: onAppointmentsTap,
              onFabTap: onFabTap,
              fabTooltip: fabTooltip,
              bottomPadding: bottomPadding,
              colors: colors,
            ),
          ),
        ),
      ),
    );
  }
}

class _BarContent extends StatelessWidget {
  const _BarContent({
    required this.activeTab,
    required this.onTasksTap,
    required this.onAppointmentsTap,
    this.onFabTap,
    this.fabTooltip,
    required this.bottomPadding,
    required this.colors,
  });

  final AppBottomTab activeTab;
  final VoidCallback onTasksTap;
  final VoidCallback onAppointmentsTap;
  final VoidCallback? onFabTap;
  final String? fabTooltip;
  final double bottomPadding;
  final AppColors colors;

  /// En modo oscuro, la píldora debe usar una superficie ligeramente
  /// elevada para distinguirse del fondo negro puro.
  bool get _isDark => colors.canvas.computeLuminance() < 0.05;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Píldora con glassmorphism (igual que el AppBar)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: ClipRRect(
              borderRadius: AppRadius.brPill,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  height: 72,
                  decoration: BoxDecoration(
                    color: colors.canvas.withValues(alpha: 0.7),
                    borderRadius: AppRadius.brPill,
                    border: Border.all(
                      color: _isDark
                          ? colors.ink.withValues(alpha: 0.18)
                          : colors.ink.withValues(alpha: 0.12),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _NeuTabChip(
                          icon: Icons.checklist_rounded,
                          label: 'Tareas',
                          active: activeTab == AppBottomTab.tasks,
                          onTap: onTasksTap,
                          colors: colors,
                          isDark: _isDark,
                        ),
                      ),
                      const SizedBox(width: 88),
                      Expanded(
                        child: _NeuTabChip(
                          icon: Icons.event_outlined,
                          label: 'Citas',
                          active: activeTab == AppBottomTab.appointments,
                          onTap: onAppointmentsTap,
                          colors: colors,
                          isDark: _isDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // FAB circular flotando centrado — mantiene neumorfismo
          _NeuFab(
            onTap: onFabTap,
            tooltip: fabTooltip,
            colors: colors,
            isDark: _isDark,
          ),
        ],
      ),
    );
  }
}

/// Chip de pestaña dentro de la barra.
class _NeuTabChip extends StatelessWidget {
  const _NeuTabChip({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    required this.colors,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final AppColors colors;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    // Claro: negro cuando activo, gris cuando inactivo.
    // Oscuro: blanco cuando activo, gris cuando inactivo.
    final iconColor = active ? colors.ink : colors.muted;
    final textColor = active ? colors.ink : colors.muted;

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.brPill,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              label,
              style: AppTypography.bodySmStrong.copyWith(color: textColor),
            ),
          ],
        ),
      ),
    );
  }
}

/// FAB circular adaptado al tema.
class _NeuFab extends StatelessWidget {
  const _NeuFab({
    this.onTap,
    this.tooltip,
    required this.colors,
    required this.isDark,
  });

  final VoidCallback? onTap;
  final String? tooltip;
  final AppColors colors;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: SizedBox(
        width: 72,
        height: 72,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.brFull,
          child: Container(
            decoration: BoxDecoration(
              color: colors.primary,
              shape: BoxShape.circle,
              boxShadow: isDark
                  ? [
                      // Modo oscuro: glow luminoso doble alrededor del FAB blanco
                      BoxShadow(
                        color: colors.primary.withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: Offset.zero,
                      ),
                      BoxShadow(
                        color: colors.shadowDark,
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [
                      // Modo claro: sombra oscura pronunciada
                      BoxShadow(
                        color: colors.shadowDark,
                        blurRadius: 16,
                        offset: const Offset(4, 8),
                      ),
                    ],
            ),
            child: Center(
              child: Icon(
                Icons.add,
                size: 36,
                color: isDark ? colors.canvasSofter : colors.onPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
