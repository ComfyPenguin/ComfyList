import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'notifications_service.dart';

/// Servicio de notificaciones de la app.
///
/// Se construye e inicializa en `main()` (best-effort) y se inyecta aquí con la
/// misma instancia, de modo que programar un aviso no dependa de volver a
/// preparar el plugin.
final notificationsServiceProvider = Provider<NotificationsService>(
  (ref) => throw UnimplementedError(
    'Sobrescribe notificationsServiceProvider en main() con la instancia '
    'inicializada.',
  ),
);

/// Si los avisos pueden sonar a su hora.
///
/// En Android eso depende del permiso de alarmas exactas, que es del sistema y
/// concede el usuario a mano; donde no hay nada que conceder cuenta como
/// concedido, para que la app no pida lo que no existe.
final exactAlarmsGrantedProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(notificationsServiceProvider);
  if (!service.supportsExactAlarms) return true;
  return service.canScheduleExact();
});
