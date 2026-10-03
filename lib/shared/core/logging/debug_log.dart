import 'package:flutter/foundation.dart';

/// Log que se queda en desarrollo.
///
/// `debugPrint` sigue escribiendo en release —lo que el compilador elimina son
/// los `assert`—, así que cualquier cosa que identifique a una cuenta (correo,
/// uid, datos del token) pasa por aquí para no acabar en el logcat del móvil.
void debugLog(String message) {
  if (kDebugMode) debugPrint(message);
}
