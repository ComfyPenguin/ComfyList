import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/core/theme/app_spacing.dart';
import '../../../../shared/core/theme/app_theme.dart';
import '../../../../shared/core/theme/app_typography.dart';
import '../../../../shared/data/notifications/notifications_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../settings/presentation/providers/settings_state.dart';

/// Aviso de que el recordatorio de esta cita no va a sonar.
///
/// Los motivos son del usuario, no de la cita: o los avisos están apagados en la
/// app, o el sistema los tiene bloqueados. Mientras no se sepa no ocupa nada,
/// para que la pantalla no dé un salto al llegar la respuesta.
class ReminderWarning extends ConsumerWidget {
  const ReminderWarning({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsProvider);
    final enabled = switch (state) {
      SettingsData(:final settings) => settings.notificationsEnabled,
      _ => null,
    };
    final systemAllows = ref.watch(systemAllowsNotificationsProvider).value;

    final message = switch ((enabled, systemAllows)) {
      (false, _) =>
        'Avisos apagados en Ajustes: no te llegará el recordatorio.',
      (true, false) =>
        'El sistema bloquea los avisos de la app: no te llegará el '
            'recordatorio.',
      _ => null,
    };
    if (message == null) return const SizedBox.shrink();

    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 18,
            color: colors.warning,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySm.copyWith(color: colors.body),
            ),
          ),
        ],
      ),
    );
  }
}
