/// Grosor de los trazos del sistema de diseño.
class AppStroke {
  AppStroke._();

  /// Hairline de contorno sobre `canvas` — la pareja de `AppColors.cardBorder`.
  /// Lo comparten cards, inputs, pickers y el chrome del shell.
  static const double hairline = 1.2;

  /// Trazo de un campo en foco o en error: más grueso que el hairline para que
  /// el estado activo se lea sobre el contorno en reposo.
  static const double focused = 1.5;
}
