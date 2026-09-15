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

  /// Veces que se ha programado algo, aunque después se reemplace el aviso.
  int scheduleCalls = 0;

  /// Veces que se ha llevado al usuario a conceder el permiso del sistema.
  int requestExactAlarmsCalls = 0;

  /// Veces que se ha pedido el permiso de notificaciones.
  int requestNotificationPermissionCalls = 0;

  /// Lo que contesta el sistema al pedir el permiso de notificaciones.
  bool notificationPermissionGranted = true;

  @override
  Future<bool> requestNotificationPermission() async {
    requestNotificationPermissionCalls++;
    // Como en el sistema: conceder el permiso hace que deje mostrar avisos.
    if (notificationPermissionGranted) notificationsAllowed = true;
    return notificationPermissionGranted;
  }

  /// Permiso de alarmas exactas del sistema. Por defecto concedido, que es el
  /// caso en el que la app no tiene nada que pedir.
  bool exactAlarmsGranted = true;

  /// Si el sistema deja mostrar avisos: permiso de notificaciones concedido y
  /// sin bloqueo por parte del usuario.
  bool notificationsAllowed = true;

  @override
  bool get supportsExactAlarms => true;

  @override
  bool get supportsNotifications => true;

  @override
  Future<bool> systemAllowsNotifications() async => notificationsAllowed;

  @override
  Future<bool> canScheduleExact() async => exactAlarmsGranted;

  @override
  Future<bool> requestExactAlarms() async {
    requestExactAlarmsCalls++;
    // La pantalla del sistema es de mentira: el usuario siempre lo concede.
    exactAlarmsGranted = true;
    return true;
  }

  @override
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime when,
  }) async {
    scheduleCalls++;
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
