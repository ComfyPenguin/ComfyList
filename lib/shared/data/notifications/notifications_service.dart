import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Servicio de notificaciones locales.
///
/// Alcance actual: solo init + permisos. La preferencia on/off vive en
/// `SettingsTable` (Drift) y se consulta desde la UI. La lógica de scheduling
/// queda fuera de este alcance — se añadirá cuando se introduzcan tareas
/// con `dueDate`.
class NotificationsService {
  NotificationsService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    // v21+: initialize toma el parámetro `settings` como named (no posicional).
    await _plugin.initialize(settings: initSettings);

    if (Platform.isAndroid) {
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
}
