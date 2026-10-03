import 'package:flutter/material.dart';

/// Tokens de border-radius.
///
/// La firma geométrica del sistema es el pill (999 px) — todo elemento
/// interactivo se redondea ahí salvo el tab-toggle y `button-large-rounded`.
/// Las cards de contenido usan `xl` (16 px) y los tiles de las listas `tile`
/// (32 px), con `joined` (6 px) en las juntas de un grupo.
class AppRadius {
  AppRadius._();

  static const double none = 0;
  static const double md = 8;       // inputs / nested rows
  static const double lg = 12;      // chrome secundario
  static const double xl = 16;      // canonical card radius
  static const double tile = 32;    // tile de lista / campo card
  static const double joined = 6;   // esquina interior de dos tiles unidos
  static const double pillTab = 36; // tab-toggle (off-pill)
  static const double dialog = pillTab; // popups / diálogos modales
  static const double pill = 999;   // pill signature
  static const double full = 9999;  // círculos (icon-button-circular)

  // Helpers Radius
  static const Radius rMd = Radius.circular(md);
  static const Radius rLg = Radius.circular(lg);
  static const Radius rXl = Radius.circular(xl);
  static const Radius rTile = Radius.circular(tile);
  static const Radius rJoined = Radius.circular(joined);
  static const Radius rPillTab = Radius.circular(pillTab);
  static const Radius rDialog = Radius.circular(dialog);
  static const Radius rPill = Radius.circular(pill);
  static const Radius rFull = Radius.circular(full);

  // Helpers BorderRadius
  static const BorderRadius brMd = BorderRadius.all(rMd);
  static const BorderRadius brLg = BorderRadius.all(rLg);
  static const BorderRadius brXl = BorderRadius.all(rXl);
  static const BorderRadius brTile = BorderRadius.all(rTile);
  static const BorderRadius brPillTab = BorderRadius.all(rPillTab);
  static const BorderRadius brDialog = BorderRadius.all(rDialog);
  static const BorderRadius brPill = BorderRadius.all(rPill);
  static const BorderRadius brFull = BorderRadius.all(rFull);

  /// Radios de un tile dentro de un grupo unido: [tile] en los extremos libres
  /// y [joined] en las juntas. Un grupo de un solo elemento queda redondeado
  /// entero.
  static BorderRadius joinedGroup({
    required bool isFirst,
    required bool isLast,
  }) {
    return BorderRadius.only(
      topLeft: isFirst ? rTile : rJoined,
      topRight: isFirst ? rTile : rJoined,
      bottomLeft: isLast ? rTile : rJoined,
      bottomRight: isLast ? rTile : rJoined,
    );
  }
}
