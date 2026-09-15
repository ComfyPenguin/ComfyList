import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/data/notifications/notifications_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/settings_state.dart';
import 'settings_tile.dart';

/// Toggle para activar o desactivar las notificaciones.
class NotificationsToggle extends ConsumerWidget {
  const NotificationsToggle({
    super.key,
    this.isFirst = true,
    this.isLast = true,
  });

  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return SettingsTile(
      icon: Icons.notifications_none_rounded,
      title: 'Notificaciones',
      enabled: state is! SettingsError,
      isFirst: isFirst,
      isLast: isLast,
      trailing: SettingsSwitch(
        state: state,
        value: (settings) => settings.notificationsEnabled,
        onChanged: (enabled) async {
          // El permiso del sistema se pide al encender los avisos, no al abrir
          // la app: hasta que el usuario no los quiere, no hay nada que pedir.
          // Si lo deniega, la fila se queda apagada en vez de prometer avisos
          // que el sistema no va a mostrar.
          final service = ref.read(notificationsServiceProvider);
          if (enabled && !await service.requestNotificationPermission()) return;
          await notifier.setNotificationsEnabled(enabled);
        },
      ),
    );
  }
}
