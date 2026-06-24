/// Tokens de espaciado — base 4 px (DESIGN.md — Uber-inspired).
///
/// Mapeo a los tokens del DESIGN.md:
///   xxs 4  · xs 6  · sm 8  · md 12 · lg 16 · xl 20 · xxl 24 · xxxl 32
///
/// `section` se conserva para gaps verticales muy grandes
/// (padding inferior de listas largas, fin de página).
class AppSpacing {
  AppSpacing._();

  static const double xxs = 4;
  static const double xs = 6;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double xxxxl = 48;
  static const double section = 64;
}
