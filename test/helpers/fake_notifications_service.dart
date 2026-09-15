import 'package:comfy_list/shared/data/notifications/notifications_service.dart';

/// Registro de un aviso programado por [FakeNotificationsService].
typedef ScheduledNotification = ({
  int id,
  String title,
  String body,
  DateTime when,
});

/// Servicio de notificaciones de mentira: apunta lo que se programa y lo que se
/// quita, sin plugin de por medio.
class FakeNotificationsService implements NotificationsService {
  final scheduled = <ScheduledNotification>[];

  /// Ids quitados de uno en uno.
  final cancelled = <int>[];

  /// Veces que se ha limpiado el plan entero.
  int cancelCalls = 0;

  @override
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime when,
  }) async {
    // El plugin identifica cada aviso por su id, así que volver a programarlo
    // reemplaza al anterior en lugar de añadir otro.
    scheduled.removeWhere((notification) => notification.id == id);
    scheduled.add((id: id, title: title, body: body, when: when));
  }

  @override
  Future<void> cancel(int id) async {
    cancelled.add(id);
    scheduled.removeWhere((notification) => notification.id == id);
  }

  @override
  Future<void> cancelAll() async {
    cancelCalls++;
    scheduled.clear();
  }

  @override
  Future<void> init() async {}
}
