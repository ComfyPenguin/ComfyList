import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// Canal por el que salen los recordatorios de citas.
const _channelId = 'appointments';
const _channelName = 'Recordatorios de citas';
const _channelDescription = 'Avisos antes de que empiece una cita.';

/// Servicio de notificaciones locales.
///
/// Solo expone lo que la app necesita: preparar el plugin, programar un aviso
/// y quitarlos todos. La preferencia on/off vive en `SettingsTable` (Drift) y
/// la lógica de qué avisar vive en el planificador de citas.
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

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    // v21+: initialize toma el parámetro `settings` como named (no posicional).
    await _plugin.initialize(settings: initSettings);

    if (_isAndroid) {
      // Android 13+ requiere POST_NOTIFICATIONS en runtime.
      try {
        await _plugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
      } catch (e) {
        debugPrint('No se pudieron pedir permisos de notificaciones: $e');
      }
    }

    _initialized = true;
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

  /// Alarma exacta si el sistema la concede; si no, el plugin la aproxima.
  Future<AndroidScheduleMode> _scheduleMode() async {
    _canScheduleExact ??= await _resolveCanScheduleExact();
    return _canScheduleExact!
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
  }

  Future<bool> _resolveCanScheduleExact() async {
    if (!_isAndroid) return false;
    try {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>()
              ?.canScheduleExactNotifications() ??
          false;
    } catch (e) {
      return false;
    }
  }
}
