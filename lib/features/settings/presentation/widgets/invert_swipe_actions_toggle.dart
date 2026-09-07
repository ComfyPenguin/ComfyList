import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/core/theme/app_radius.dart';
import '../../../../shared/core/theme/app_spacing.dart';
import '../../../../shared/core/theme/app_theme.dart';
import '../../../../shared/core/theme/app_typography.dart';
import '../providers/settings_provider.dart';
import '../providers/settings_state.dart';

/// Toggle para invertir el lado de las acciones del deslizamiento:
/// al activarlo, «Eliminar» queda a la izquierda y «Completar» a la derecha.
class InvertSwipeActionsToggle extends ConsumerWidget {
  const InvertSwipeActionsToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final colors = context.colors;

    final content = switch (state) {
      SettingsData(:final settings) => _Row(
          value: settings.invertSwipeActions,
          onChanged: notifier.setInvertSwipeActions,
        ),
      SettingsError() => Text(
          'No se ha podido leer la preferencia.',
          style: AppTypography.bodyMd.copyWith(color: colors.error),
        ),
      SettingsInitial() || SettingsLoading() => const SizedBox(
          height: 56,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
    };

    return Container(
      decoration: BoxDecoration(
        color: colors.canvasSoft,
        borderRadius: AppRadius.brXl,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: content,
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Invertir acciones al deslizar',
                style: AppTypography.bodyMdStrong.copyWith(color: colors.ink),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                value
                    ? 'Deslizar a la derecha elimina y a la izquierda completa.'
                    : 'Deslizar a la izquierda elimina y a la derecha completa.',
                style: AppTypography.bodySm.copyWith(color: colors.body),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Switch.adaptive(value: value, onChanged: onChanged),
      ],
    );
  }
}
