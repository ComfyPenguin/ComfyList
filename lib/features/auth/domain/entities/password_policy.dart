/// Reglas que debe cumplir una contraseña nueva.
///
/// Solo longitud y variedad: exigir mayúsculas, símbolos y demás empuja a
/// contraseñas peores —una mayúscula y un número pegado al final— y molesta en
/// el teclado del móvil sin ganar gran cosa. Es lo que recomienda el NIST:
/// la longitud pesa más que la variedad.
enum PasswordRule {
  minLength,
  letter,
  number;

  /// `true` si [password] cumple esta regla.
  ///
  /// Las clases de letra y dígito son Unicode, para que una `ñ` o una `á`
  /// cuenten como letra y no se rechace una contraseña en español.
  bool isMetBy(String password) => switch (this) {
    PasswordRule.minLength => password.length >= PasswordPolicy.minLength,
    PasswordRule.letter => _letter.hasMatch(password),
    PasswordRule.number => _number.hasMatch(password),
  };

  static final RegExp _letter = RegExp(r'\p{L}', unicode: true);
  static final RegExp _number = RegExp(r'\p{Nd}', unicode: true);
}

/// Política de contraseñas de la app, en un único sitio.
///
/// El servidor de Firebase solo impone una longitud mínima y no se puede
/// configurar sin Identity Platform, así que la comprobación vive aquí y se
/// aplica antes de llamar a la API.
class PasswordPolicy {
  PasswordPolicy._();

  /// Longitud mínima exigida.
  static const int minLength = 8;

  /// Reglas que [password] todavía no cumple, en el orden en que se piden.
  static List<PasswordRule> unmet(String password) => [
    for (final rule in PasswordRule.values)
      if (!rule.isMetBy(password)) rule,
  ];

  /// `true` si [password] cumple la política entera.
  static bool isValid(String password) => unmet(password).isEmpty;
}
