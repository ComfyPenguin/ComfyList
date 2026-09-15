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
