import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';

/// Campo de texto del DS — usa `inputDecorationTheme` del `AppTheme`
/// (DESIGN.md `text-input`).
///
/// Con [cardStyle] se renderiza como una card de citas (fondo `canvas`,
/// borde hairline y radio grande) en lugar del input soft por defecto.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.maxLines = 1,
    this.cardStyle = false,
    this.suffixIcon,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? errorText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final int maxLines;

  /// Renderiza el campo como una card de citas (radio grande + borde hairline).
  final bool cardStyle;

  /// Icono opcional al final del campo (p. ej. toggle de visibilidad).
  final Widget? suffixIcon;

  /// Radio de la card del campo — espejo de las cards de citas.
  static const double _cardRadius = 32;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final baseDecoration = InputDecoration(
      labelText: label,
      hintText: hint,
      errorText: errorText,
    );

    if (!cardStyle) {
      return TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        enabled: enabled,
        maxLines: obscureText ? 1 : maxLines,
        decoration: baseDecoration.copyWith(suffixIcon: suffixIcon),
      );
    }

    final isDark = colors.canvas.computeLuminance() < 0.05;
    final borderColor = isDark
        ? colors.ink.withValues(alpha: 0.18)
        : colors.ink.withValues(alpha: 0.12);

    final cardDecoration = baseDecoration.copyWith(
      filled: true,
      fillColor: colors.canvas,
      // Con contenido dentro la label flota hacia el borde: añadimos
      // padding vertical para que el campo respire dentro de la card.
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 22,
      ),
      labelStyle: AppTypography.bodySm.copyWith(color: colors.body),
      floatingLabelStyle: AppTypography.bodySmStrong.copyWith(color: colors.ink),
      hintStyle: AppTypography.bodyMd.copyWith(color: colors.mutedSoft),
      suffixIcon: suffixIcon,
      border: _outline(borderColor),
      enabledBorder: _outline(borderColor),
      focusedBorder: _outline(colors.ink, width: 1.5),
      errorBorder: _outline(colors.error),
      focusedErrorBorder: _outline(colors.error, width: 1.5),
    );

    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      enabled: enabled,
      maxLines: obscureText ? 1 : maxLines,
      decoration: cardDecoration,
    );
  }

  OutlineInputBorder _outline(Color color, {double width = 1.2}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(_cardRadius),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}