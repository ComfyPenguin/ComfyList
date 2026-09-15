import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/core/theme/app_theme.dart';
import '../../../../shared/data/notifications/notifications_provider.dart';
import 'settings_tile.dart';

/// Fila para conceder el permiso de alarmas exactas del sistema.
///
/// No es una preferencia de la app y no se guarda en ningún sitio: es un acceso
/// especial que concede el usuario a mano en los ajustes del sistema, así que la
/// pantalla solo monta la fila mientras falte.
class ExactAlarmsTile extends ConsumerWidget {
  const ExactAlarmsTile({super.key, this.isFirst = true, this.isLast = true});

  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SettingsTile(
      icon: Icons.notifications_active_rounded,
      title: 'Alarmas exactas',
      description: 'Sin este permiso los avisos pueden llegarte con retraso.',
      isFirst: isFirst,
      isLast: isLast,
      trailing: Icon(
        Icons.arrow_outward_rounded,
        size: 20,
        color: context.colors.muted,
      ),
      onTap: () async {
        final granted = await ref
            .read(notificationsServiceProvider)
            .requestExactAlarms();
        if (!granted || !context.mounted) return;
        // El permiso lo tiene el sistema, así que hay que volver a preguntarle
        // por él. Quien escucha este provider es quien rehace los avisos ya
        // programados, que se quedaron en modo aproximado.
        ref.invalidate(exactAlarmsGrantedProvider);
      },
    );
  }
}
