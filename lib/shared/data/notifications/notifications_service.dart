import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// Canal por el que salen los recordatorios de citas.
const _channelId = 'appointments';
const _channelName = 'Recordatorios de citas';
const _channelDescription = 'Avisos antes de que empiece una cita.';

/// Servicio de notificaciones locales.
///
/// Solo expone lo que la app necesita: preparar el plugin, programar un aviso,
/// quitarlos todos o quitar uno. La preferencia on/off vive en `SettingsTable`
/// (Drift) y la lógica de qué avisar vive en el planificador de citas.
///
/// Los permisos no se piden al preparar el plugin: se piden cuando el usuario
/// enciende los avisos, que es cuando tienen sentido.
///
/// Las llamadas al plugin son best-effort — en Linux desktop no hay soporte y
/// el aviso se descarta sin tumbar la app.
class NotificationsService {
  NotificationsService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  bool _initialized = false;

  /// Si el sistema permite alarmas exactas; se resuelve la primera vez que hace
  /// falta, porque pregunta al plugin.
  bool? _canScheduleExact;

  Future<void> init() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);

    // v21+: initialize toma el parámetro `settings` como named (no posicional).
    await _plugin.initialize(settings: initSettings);

    _initialized = true;
  }

  /// Pide el permiso de notificaciones del sistema —Android 13+ lo exige en
  /// runtime— y devuelve si quedó concedido. Donde no hay nada que pedir cuenta
  /// como concedido, para que la app no se quede sin poder encender los avisos.
  Future<bool> requestNotificationPermission() async {
    if (!_isAndroid) return true;
    try {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestNotificationsPermission() ??
          false;
    } catch (e) {
      debugPrint('No se pudo pedir el permiso de notificaciones: $e');
      return false;
    }
  }

  /// Programa un aviso para [when], en la hora local del dispositivo.
  ///
  /// La fecha viaja al plugin como instante en UTC: es lo que se quiere —que
  /// suene en el momento calculado— y así no depende de la zona del sistema ni
  /// de que carguemos la base de datos horaria. El plugin rechaza las fechas
  /// pasadas; aquí eso se traga en vez de propagarse.
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime when,
  }) async {
    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(when.toUtc(), tz.UTC),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: await _scheduleMode(),
      );
    } catch (e) {
      debugPrint('No se pudo programar el aviso $id: $e');
    }
  }

  /// Quita un aviso programado por su id.
  Future<void> cancel(int id) async {
    try {
      await _plugin.cancel(id: id);
    } catch (e) {
      debugPrint('No se pudo cancelar el aviso $id: $e');
    }
  }

  /// Quita los avisos programados. Los ya mostrados no se tocan: si el usuario
  /// los está viendo, no es cosa nuestra hacerlos desaparecer.
  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAllPendingNotifications();
    } catch (e) {
      debugPrint('No se pudieron cancelar los avisos: $e');
    }
  }

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Si en esta plataforma hay un permiso de alarmas exactas que conceder. Sin
  /// él los avisos caen en una alarma aproximada y pueden llegar tarde.
  bool get supportsExactAlarms => _isAndroid;

  /// Si el sistema deja programar avisos exactos ahora mismo.
  Future<bool> canScheduleExact() async {
    if (!_isAndroid) return false;
    try {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.canScheduleExactNotifications() ??
          false;
    } catch (e) {
      return false;
    }
  }

  /// Manda al usuario a la pantalla del sistema donde se concede el permiso de
  /// alarmas exactas y devuelve si quedó concedido. La app no puede concederlo
  /// por su cuenta: es un acceso especial que se da a mano.
  Future<bool> requestExactAlarms() async {
    if (!_isAndroid) return false;
    try {
      final granted =
          await _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestExactAlarmsPermission() ??
          false;
      // El modo de programación se resuelve una sola vez por sesión, así que la
      // respuesta anterior deja de valer en cuanto el permiso cambia.
      _canScheduleExact = granted;
      return granted;
    } catch (e) {
      debugPrint('No se pudo pedir el permiso de alarmas exactas: $e');
      return false;
    }
  }

  /// Alarma exacta si el sistema la concede; si no, el plugin la aproxima.
  Future<AndroidScheduleMode> _scheduleMode() async {
    _canScheduleExact ??= await canScheduleExact();
    return _canScheduleExact!
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
  }
}
