import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Devuelve el momento actual.
typedef Now = DateTime Function();

/// Cada cuánto vuelven a pedir datos los watchers de la app.
const Duration defaultPollInterval = Duration(seconds: 15);

/// Cadencia del polling, en un solo sitio para toda la app.
final pollIntervalProvider = Provider<Duration>((ref) => defaultPollInterval);

/// Reloj de la app: la única fuente de «ahora». Los tests lo sobrescriben con
/// una fecha fija para no depender del reloj de la máquina.
///
/// Es una función y no un `DateTime` a propósito: un provider guarda su valor,
/// así que uno de tipo `DateTime` congelaría «hoy» durante toda la sesión.
final clockProvider = Provider<Now>((ref) => DateTime.now);
