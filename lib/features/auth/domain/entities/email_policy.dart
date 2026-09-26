/// Validación del correo que pide la app.
///
/// No pretende cubrir el RFC entero —hay direcciones válidas que ninguna
/// expresión razonable acepta—, solo descartar lo que el servidor va a
/// rechazar: algo antes de la `@`, un dominio con punto y ni un espacio. Es la
/// expresión que usa el propio HTML5 para `input[type=email]`, con el punto del
/// dominio exigido.
class EmailPolicy {
  EmailPolicy._();

  /// `true` si [email] tiene forma de correo. Se ignoran los espacios de los
  /// extremos, que es lo que suele venir del autocompletado.
  static bool isValid(String email) => _pattern.hasMatch(email.trim());

  static final RegExp _pattern = RegExp(
    r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}"
    r'[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$',
  );
}
