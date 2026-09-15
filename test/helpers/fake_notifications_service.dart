import 'package:comfy_list/shared/data/notifications/notifications_service.dart';

/// Registro de un aviso programado por [FakeNotificationsService].
typedef ScheduledNotification = ({
  int id,
  String title,
  String body,
  DateTime when,
});

/// Servicio de notificaciones de mentira: apunta lo que se programa y cuántas
/// veces se limpia, sin plugin de por medio.
class FakeNotificationsService implements NotificationsService {
  final scheduled = <ScheduledNotification>[];
  int cancelCalls = 0;

  @override
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime when,
  }) async {
    scheduled.add((id: id, title: title, body: body, when: when));
  }

  @override
  Future<void> cancelAll() async {
    cancelCalls++;
    scheduled.clear();
  }

  @override
  Future<void> init() async {}
}
