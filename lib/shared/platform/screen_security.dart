import 'package:flutter/services.dart';

/// Blindaje de la pantalla contra capturas y miniaturas en el conmutador de
/// apps, mientras haya datos sensibles a la vista (las pantallas de acceso).
///
/// Solo Android lo implementa, con `FLAG_SECURE`; donde no hay implementación
/// el canal no está y la app sigue igual. Por eso las llamadas nunca fallan:
/// esto es un extra, no un requisito para poder entrar.
class ScreenSecurity {
  ScreenSecurity._();

  /// Nombre del canal que implementa `MainActivity` en Android.
  static const String channelName = 'comfy_list/screen_security';

  static const MethodChannel _channel = MethodChannel(channelName);

  static Future<void> enable() => _setSecure(true);

  static Future<void> disable() => _setSecure(false);

  static Future<void> _setSecure(bool secure) async {
    try {
      await _channel.invokeMethod<void>('setSecure', <String, bool>{
        'secure': secure,
      });
    } on MissingPluginException {
      // Plataforma sin el canal: nada que blindar.
    }
  }
}
