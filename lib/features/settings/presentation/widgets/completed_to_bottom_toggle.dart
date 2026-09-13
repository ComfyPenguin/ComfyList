import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/core/theme/app_spacing.dart';
import '../../../../shared/core/theme/app_theme.dart';
import '../../../../shared/core/theme/app_typography.dart';
import '../../../../shared/ui/cards/app_card.dart';
import '../providers/settings_provider.dart';
import '../providers/settings_state.dart';

/// Toggle para decidir si las tareas completadas se mueven al final de la lista.
class CompletedToBottomToggle extends ConsumerWidget {
  const CompletedToBottomToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final colors = context.colors;

    final content = switch (state) {
      SettingsData(:final settings) => _Row(
          value: settings.completedToBottom,
          onChanged: notifier.setCompletedToBottom,
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

    return AppCard(child: content);
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
                'Tareas completadas al final',
                style: AppTypography.bodyMdStrong.copyWith(color: colors.ink),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                'Las tareas que marques como hechas se mueven al final '
                'de la lista automáticamente.',
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
