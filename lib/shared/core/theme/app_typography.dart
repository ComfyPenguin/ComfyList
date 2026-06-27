import 'package:flutter/material.dart';

/// Tokens tipográficos del sistema.
class AppTypography {
  AppTypography._();

  static const String _displayFamily = 'PlusJakartaSans';
  static const String _bodyFamily = 'PlusJakartaSans';

  // ─── Display (peso 700, sentence-case, nunca letter-spaced) ────────────

  static const TextStyle displayXxl = TextStyle(
    fontFamily: _displayFamily,
    fontSize: 52,
    fontWeight: FontWeight.w700,
    height: 64 / 52,
  );

  static const TextStyle displayXl = TextStyle(
    fontFamily: _displayFamily,
    fontSize: 36,
    fontWeight: FontWeight.w700,
    height: 44 / 36,
  );

  static const TextStyle displayLg = TextStyle(
    fontFamily: _displayFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 40 / 32,
  );

  static const TextStyle displayMd = TextStyle(
    fontFamily: _displayFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 32 / 24,
  );

  static const TextStyle displaySm = TextStyle(
    fontFamily: _displayFamily,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 28 / 20,
  );

  // ─── Body (peso 400/500) ───────────────────────────────────────────────

  static const TextStyle bodyLg = TextStyle(
    fontFamily: _bodyFamily,
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 24 / 18,
  );

  static const TextStyle bodyMd = TextStyle(
    fontFamily: _bodyFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 24 / 16,
  );

  static const TextStyle bodyMdStrong = TextStyle(
    fontFamily: _bodyFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 20 / 16,
  );

  static const TextStyle bodySm = TextStyle(
    fontFamily: _bodyFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
  );

  static const TextStyle bodySmStrong = TextStyle(
    fontFamily: _bodyFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 16 / 14,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: _bodyFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 20 / 12,
  );

  // ─── Botones ───────────────────────────────────────────────────────────

  /// Etiqueta del botón grande (button-large-rounded).
  static const TextStyle buttonLarge = TextStyle(
    fontFamily: _bodyFamily,
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 24 / 18,
  );

  /// Etiqueta del botón por defecto (button-primary / button-secondary).
  static const TextStyle buttonMd = TextStyle(
    fontFamily: _bodyFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 20 / 16,
  );

  /// Link de navegación (nav-link).
  static const TextStyle navLink = bodyMdStrong;
}
