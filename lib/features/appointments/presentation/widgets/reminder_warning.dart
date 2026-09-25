import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../routing/routes.dart';
import '../../../../shared/core/theme/app_radius.dart';
import '../../../../shared/core/theme/app_spacing.dart';
import '../../../../shared/core/theme/app_theme.dart';
import '../../../../shared/core/theme/app_typography.dart';
import '../../../../shared/data/notifications/notifications_provider.dart';
import '../../../../shared/ui/toast/app_toast.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../settings/presentation/providers/settings_state.dart';

/// Aviso de que el recordatorio de esta cita no va a sonar, con la salida a
/// mano: se puede pulsar.
///
/// Los motivos son del usuario, no de la cita: o los avisos están apagados en la
/// app —y entonces el arreglo está en Ajustes—, o el sistema los tiene
/// bloqueados —y entonces se le pide el permiso aquí mismo—. Mientras no se sepa
/// no ocupa nada, para que la pantalla no dé un salto al llegar la respuesta.
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

    // Ajustes se abre encima para no perder lo que haya escrito en la cita.
    final VoidCallback onTap = enabled == false
        ? () => context.push(Routes.settings)
        : () => _askPermission(context, ref);

    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brPill,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.xxs,
          ),
          child: Row(
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
              const SizedBox(width: AppSpacing.xs),
              Icon(Icons.chevron_right_rounded, size: 18, color: colors.muted),
            ],
          ),
        ),
      ),
    );
  }

  /// Pide el permiso de notificaciones al sistema; si lo concede, el aviso se
  /// va solo.
  Future<void> _askPermission(BuildContext context, WidgetRef ref) async {
    final granted = await ref
        .read(notificationsServiceProvider)
        .requestNotificationPermission();
    if (!context.mounted) return;

    if (!granted) {
      // El sistema puede negarse sin volver a preguntar, y sus ajustes no hay
      // forma de abrirlos desde aquí: al menos que no se quede en silencio.
      AppToast.show(
        context,
        'Sigue bloqueado: actívalos en los ajustes del sistema.',
      );
      return;
    }
    ref.invalidate(systemAllowsNotificationsProvider);
  }
}
