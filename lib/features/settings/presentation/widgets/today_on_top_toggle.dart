import 'package:flutter/material.dart';

import 'settings_tile.dart';

/// Ajuste pendiente de implementación: fijar las citas de hoy arriba
/// en la pantalla de citas. Marcado como «próximamente» hasta que se
/// implemente.
class TodayOnTopToggle extends StatelessWidget {
  const TodayOnTopToggle({super.key, this.isFirst = true, this.isLast = true});

  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      icon: Icons.vertical_align_top_rounded,
      title: 'Citas de hoy arriba',
      enabled: false,
      isFirst: isFirst,
      isLast: isLast,
      trailing: const SettingsTileBadge('Próximamente'),
    );
  }
}
