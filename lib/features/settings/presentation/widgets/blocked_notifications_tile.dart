import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/core/theme/app_theme.dart';
import '../../../../shared/data/notifications/notifications_provider.dart';
import '../../../../shared/ui/toast/app_toast.dart';
import 'settings_tile.dart';

/// Fila de que el sistema no deja mostrar los avisos de la app.
///
/// No es una preferencia —esa está encendida— sino estado del sistema: el
/// permiso de notificaciones sin conceder o los avisos de la app bloqueados
/// desde los ajustes del sistema. La pantalla solo la monta mientras ocurra, así
/// que desaparece sola en cuanto dejan de estar bloqueados.
class BlockedNotificationsTile extends ConsumerWidget {
  const BlockedNotificationsTile({
    super.key,
    this.isFirst = true,
    this.isLast = true,
  });

  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SettingsTile(
      icon: Icons.notifications_off_outlined,
      title: 'Avisos bloqueados',
      description:
          'El sistema no deja que la app te avise, así que los '
          'recordatorios no sonarán.',
      isFirst: isFirst,
      isLast: isLast,
      trailing: Icon(
        Icons.chevron_right_rounded,
        size: 20,
        color: context.colors.muted,
      ),
      onTap: () async {
        final service = ref.read(notificationsServiceProvider);
        await service.requestNotificationPermission();
        // El permiso lo tiene el sistema, así que hay que volver a preguntarle:
        // puede seguir bloqueado aunque se acabe de conceder, si los avisos de
        // la app están apagados en los ajustes del sistema.
        ref.invalidate(systemAllowsNotificationsProvider);
        if (await service.systemAllowsNotifications() || !context.mounted) {
          return;
        }
        // El sistema deja de preguntar tras dos negativas y sus ajustes no hay
        // forma de abrirlos desde aquí: al menos que no se quede en silencio.
        AppToast.show(context, AppToast.notificationsStillBlocked);
      },
    );
  }
}
