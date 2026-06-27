import 'package:flutter/material.dart';

/// Tokens de border-radius.
///
/// La firma geométrica del sistema es el pill (999 px) — todo elemento
/// interactivo se redondea ahí salvo el tab-toggle y `button-large-rounded`.
/// Las cards usan siempre `xl` (16 px).
class AppRadius {
  AppRadius._();

  static const double none = 0;
  static const double md = 8;       // inputs / nested rows
  static const double lg = 12;      // chrome secundario
  static const double xl = 16;      // canonical card radius
  static const double pillTab = 36; // tab-toggle (off-pill)
  static const double pill = 999;   // pill signature
  static const double full = 9999;  // círculos (icon-button-circular)

  // Helpers Radius
  static const Radius rMd = Radius.circular(md);
  static const Radius rLg = Radius.circular(lg);
  static const Radius rXl = Radius.circular(xl);
  static const Radius rPillTab = Radius.circular(pillTab);
  static const Radius rPill = Radius.circular(pill);
  static const Radius rFull = Radius.circular(full);

  // Helpers BorderRadius
  static const BorderRadius brMd = BorderRadius.all(rMd);
  static const BorderRadius brLg = BorderRadius.all(rLg);
  static const BorderRadius brXl = BorderRadius.all(rXl);
  static const BorderRadius brPillTab = BorderRadius.all(rPillTab);
  static const BorderRadius brPill = BorderRadius.all(rPill);
  static const BorderRadius brFull = BorderRadius.all(rFull);
}
