import 'package:flutter/material.dart';

/// Tokens de color del sistema de diseño — Neumorfismo clásico suave.
/// Paleta adaptada para soportar sombras claras/oscuras sobre fondos mid-tone.
@immutable
class AppColors {
  const AppColors({
    required this.primary,
    required this.onPrimary,
    required this.ink,
    required this.body,
    required this.muted,
    required this.mutedSoft,
    required this.hairline,
    required this.hairlineSoft,
    required this.hairlineMid,
    required this.canvas,
    required this.canvasSoft,
    required this.canvasSofter,
    required this.surfacePressed,
    required this.surfaceDark,
    required this.surfaceDarkElevated,
    required this.onDark,
    required this.onDarkSoft,
    required this.link,
    required this.success,
    required this.warning,
    required this.error,
    required this.onError,
    // Neumorphic shadows
    required this.shadowLight,
    required this.shadowDark,
  });

  // CTA / texto principal
  final Color primary;
  final Color onPrimary;
  final Color ink;
  final Color body;
  final Color muted;
  final Color mutedSoft;

  // Hairlines
  final Color hairline;
  final Color hairlineSoft;
  final Color hairlineMid;

  // Superficies
  final Color canvas;
  final Color canvasSoft;
  final Color canvasSofter;
  final Color surfacePressed;
  final Color surfaceDark;
  final Color surfaceDarkElevated;

  // Sobre superficies oscuras
  final Color onDark;
  final Color onDarkSoft;

  // Links (único cromático del sistema)
  final Color link;

  // Semánticos
  final Color success;
  final Color warning;
  final Color error;
  /// Foreground sobre superficies [error] (iconos/textos del atajo de borrado).
  final Color onError;

  // Neumorphic shadows
  /// Sombra clara (arriba-izquierda) — simula luz ambiental.
  final Color shadowLight;
  /// Sombra oscura (abajo-derecha) — simula sombra proyectada.
  final Color shadowDark;

  /// Paleta Light Neumorphism — fondo mid-tone para que las sombras funcionen.
  static const AppColors light = AppColors(
    primary: Color(0xFF000000),
    onPrimary: Color(0xFFFFFFFF),
    ink: Color(0xFF1A1A1A),
    body: Color(0xFF4A4A4A),
    muted: Color(0xFF8A8A8A),
    mutedSoft: Color(0xFFB0B0B0),
    hairline: Color(0xFFD1D5DB),
    hairlineSoft: Color(0xFFE5E7EB),
    hairlineMid: Color(0xFF9CA3AF),
    canvas: Color(0xFFE8ECF1),
    canvasSoft: Color(0xFFD1D5DB),
    canvasSofter: Color(0xFFE5E7EB),
    surfacePressed: Color(0xFFD1D5DB),
    surfaceDark: Color(0xFF1A1A1A),
    surfaceDarkElevated: Color(0xFF2D2D2D),
    onDark: Color(0xFFFFFFFF),
    onDarkSoft: Color(0xFFB0B0B0),
    link: Color(0xFF2563EB),
    success: Color(0xFF16A34A),
    warning: Color(0xFFD97706),
    error: Color(0xFFDC2626),
    onError: Color(0xFFFFFFFF),
    // Neumorphic shadows for light theme
    shadowLight: Color(0xFFFFFFFF),
    shadowDark: Color(0xFFA3B1C6),
  );

  /// Paleta Dark Neumorphism — fondo negro puro con contraste elevado.
  static const AppColors dark = AppColors(
    primary: Color(0xFFFFFFFF),
    onPrimary: Color(0xFF000000),
    ink: Color(0xFFFFFFFF),
    body: Color(0xFFB0B0B0),
    muted: Color(0xFF7A7A7A),
    mutedSoft: Color(0xFF4A4A4A),
    hairline: Color(0xFF2A2A2A),
    hairlineSoft: Color(0xFF1A1A1A),
    hairlineMid: Color(0xFFAFAFAF),
    // canvas = fondo negro puro; canvasSoft/Softer = superficies elevadas
    canvas: Color(0xFF000000),
    canvasSoft: Color(0xFF1C1C1E),
    canvasSofter: Color(0xFF2C2C2E),
    surfacePressed: Color(0xFF1A1A1A),
    surfaceDark: Color(0xFF000000),
    surfaceDarkElevated: Color(0xFF1C1C1E),
    onDark: Color(0xFFFFFFFF),
    onDarkSoft: Color(0xFFAFAFAF),
    link: Color(0xFF60A5FA),
    success: Color(0xFF4ADE80),
    warning: Color(0xFFFCD34D),
    error: Color(0xFFF87171),
    onError: Color(0xFF1A1A1A),
    // Neumorphic shadows for dark theme
    // Sombra "clara": glow sutil para simular luz sobre negro
    shadowLight: Color(0xFF3A3A3A),
    // Sombra "oscura": más profunda, para simular sombra sobre negro
    shadowDark: Color(0xFF000000),
  );
}
