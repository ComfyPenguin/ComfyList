import 'package:flutter/material.dart';

import 'app_colors.dart';
export 'app_colors.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light() => _build(AppColors.light, Brightness.light);
  static ThemeData dark() => _build(AppColors.dark, Brightness.dark);

  static ThemeData _build(AppColors c, Brightness brightness) {
    final scaffold = brightness == Brightness.light
        ? Color.lerp(c.canvasSofter, c.canvasSoft, 0.35)!
        : Color.lerp(c.canvas, c.canvasSoft, 0.35)!;
    final textTheme = _buildTextTheme(c.ink, c.body, c.muted);

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: c.primary,
      onPrimary: c.onPrimary,
      // El DS no tiene segundo acento — replicamos primary como secondary
      // y usamos surfacePressed para roles auxiliares.
      secondary: c.primary,
      onSecondary: c.onPrimary,
      tertiary: c.surfacePressed,
      onTertiary: c.ink,
      error: c.error,
      onError: c.onPrimary,
      surface: c.canvas,
      onSurface: c.ink,
      surfaceContainerHighest: c.canvasSoft,
      outline: c.hairline,
      outlineVariant: c.hairlineSoft,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      // En tema claro dejamos el fondo un punto distinto del shell para
      // separar mejor el chrome flotante del contenido.
      scaffoldBackgroundColor: scaffold,
      canvasColor: scaffold,
      textTheme: textTheme,
      // Card flat (Level 0): canvas + radio xl, sin borde ni sombra.
      cardTheme: CardThemeData(
        color: c.canvas,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.brXl),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.canvas,
        foregroundColor: c.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.displaySm.copyWith(color: c.ink),
        iconTheme: IconThemeData(color: c.ink),
      ),
      // button-primary: pill negro, peso 500, padding md/md.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: c.onPrimary,
          disabledBackgroundColor: c.surfacePressed,
          disabledForegroundColor: c.muted,
          textStyle: AppTypography.buttonMd,
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.brPill),
          elevation: 0,
        ),
      ),
      // button-secondary: pill blanco con borde hairline.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.ink,
          backgroundColor: c.canvas,
          textStyle: AppTypography.buttonMd,
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.brPill),
          side: BorderSide(color: c.hairline),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.ink,
          textStyle: AppTypography.buttonMd,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.brPill),
        ),
      ),
      // text-input: fill canvas-soft, radio md (8 px). Borde solo en focus.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.canvasSoft,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        hintStyle: AppTypography.bodyMd.copyWith(color: c.mutedSoft),
        labelStyle: AppTypography.bodySm.copyWith(color: c.body),
        floatingLabelStyle: AppTypography.bodySmStrong.copyWith(color: c.ink),
        border: const OutlineInputBorder(
          borderRadius: AppRadius.brMd,
          borderSide: BorderSide.none,
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.brMd,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.brMd,
          borderSide: BorderSide(color: c.ink, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.brMd,
          borderSide: BorderSide(color: c.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.brMd,
          borderSide: BorderSide(color: c.error, width: 1.5),
        ),
      ),
      dividerTheme:
          DividerThemeData(color: c.hairline, thickness: 1, space: 1),
      // Switch ink/canvas — sin tintes de marca extra.
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? c.onPrimary : c.canvas,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? c.primary : c.hairline,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? c.primary : c.hairline,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        side: BorderSide(color: c.hairlineMid, width: 1.5),
        fillColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? c.primary : c.canvas,
        ),
        checkColor: WidgetStateProperty.all(c.onPrimary),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.brMd),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.surfaceDark,
        contentTextStyle: AppTypography.bodySm.copyWith(color: c.onDark),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.brXl),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.canvas,
        surfaceTintColor: c.canvas,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.brXl),
        titleTextStyle: AppTypography.displaySm.copyWith(color: c.ink),
        contentTextStyle: AppTypography.bodyMd.copyWith(color: c.body),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.canvas,
        // Espejo del TopBar: mismo radio y hairline (ver app_shell.dart).
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
          side: BorderSide(
            color: brightness == Brightness.light
                ? c.ink.withValues(alpha: 0.12)
                : c.ink.withValues(alpha: 0.18),
            width: 1.2,
          ),
        ),
        showDragHandle: true,
        // 2x el default M3 (32x4) para mayor affordance del drag.
        dragHandleSize: const Size(64, 4),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: c.primary,
        foregroundColor: c.onPrimary,
        elevation: 0,
        highlightElevation: 0,
        extendedTextStyle: AppTypography.buttonMd,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.brPill),
      ),
      iconTheme: IconThemeData(color: c.ink),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: c.primary),
      extensions: <ThemeExtension<dynamic>>[
        AppColorsExtension(c),
      ],
    );
  }

  static TextTheme _buildTextTheme(Color ink, Color body, Color muted) {
    return TextTheme(
      displayLarge: AppTypography.displayXxl.copyWith(color: ink),
      displayMedium: AppTypography.displayXl.copyWith(color: ink),
      displaySmall: AppTypography.displayLg.copyWith(color: ink),
      headlineLarge: AppTypography.displayLg.copyWith(color: ink),
      headlineMedium: AppTypography.displayMd.copyWith(color: ink),
      headlineSmall: AppTypography.displaySm.copyWith(color: ink),
      titleLarge: AppTypography.displaySm.copyWith(color: ink),
      titleMedium: AppTypography.bodyLg.copyWith(color: ink),
      titleSmall: AppTypography.bodyMdStrong.copyWith(color: ink),
      bodyLarge: AppTypography.bodyLg.copyWith(color: body),
      bodyMedium: AppTypography.bodyMd.copyWith(color: body),
      bodySmall: AppTypography.bodySm.copyWith(color: body),
      labelLarge: AppTypography.buttonMd.copyWith(color: ink),
      labelMedium: AppTypography.bodySmStrong.copyWith(color: ink),
      labelSmall: AppTypography.caption.copyWith(color: muted),
    );
  }
}

/// Extensión de tema que expone los tokens completos de [AppColors].
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  const AppColorsExtension(this.tokens);

  final AppColors tokens;

  @override
  AppColorsExtension copyWith({AppColors? tokens}) =>
      AppColorsExtension(tokens ?? this.tokens);

  @override
  AppColorsExtension lerp(ThemeExtension<AppColorsExtension>? other, double t) {
    // Cambio duro al alternar tema — no interpolamos entre paletas.
    return this;
  }
}

extension AppColorsContext on BuildContext {
  AppColors get colors =>
      Theme.of(this).extension<AppColorsExtension>()!.tokens;
}
