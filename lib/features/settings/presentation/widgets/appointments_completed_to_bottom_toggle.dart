import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/core/theme/app_radius.dart';
import '../../../../shared/core/theme/app_spacing.dart';
import '../../../../shared/core/theme/app_theme.dart';
import '../../../../shared/core/theme/app_typography.dart';
import '../providers/settings_provider.dart';
import '../providers/settings_state.dart';

/// Toggle para decidir si las citas completadas se mueven al final de la
/// lista de su día. Solo tiene efecto cuando «Completar citas» está activo,
/// por eso el switch se deshabilita si no lo está.
class AppointmentsCompletedToBottomToggle extends ConsumerWidget {
  const AppointmentsCompletedToBottomToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final colors = context.colors;

    final content = switch (state) {
      SettingsData(:final settings) => _Row(
          value: settings.appointmentsCompletionEnabled
              ? settings.appointmentsCompletedToBottom
              : false,
          enabled: settings.appointmentsCompletionEnabled,
          onChanged: settings.appointmentsCompletionEnabled
              ? notifier.setAppointmentsCompletedToBottom
              : null,
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
  const _Row({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final bool value;
  final bool enabled;
  final ValueChanged<bool>? onChanged;

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
                'Citas completadas al final',
                style: AppTypography.bodyMdStrong.copyWith(
                  color: enabled ? colors.ink : colors.muted,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                enabled
                    ? 'Las citas que marques como completadas se mueven al '
                        'final de la lista de ese día automáticamente.'
                    : 'Disponible al activar «Completar citas».',
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
