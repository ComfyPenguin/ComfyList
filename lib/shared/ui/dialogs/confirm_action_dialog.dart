import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../buttons/primary_button.dart';

/// Dialog de confirmación con la estética del diálogo de restablecer
/// contraseña: card con borde hairline y radio grande, título centrado y
/// CTA pill expandida. Devuelve `true` al confirmar y `false` al cancelar.
class ConfirmActionDialog extends StatelessWidget {
  const ConfirmActionDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.cancelLabel = 'Cancelar',
    this.destructive = false,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;

  /// Pinta la CTA con la paleta de error para acciones destructivas.
  final bool destructive;

  /// Helper para abrirlo con `showDialog`.
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    String cancelLabel = 'Cancelar',
    bool destructive = false,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmActionDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        destructive: destructive,
      ),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = colors.canvas.computeLuminance() < 0.05;
    final borderColor = isDark
        ? colors.ink.withValues(alpha: 0.18)
        : colors.ink.withValues(alpha: 0.12);

    return Dialog(
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.brDialog),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: colors.canvas,
          borderRadius: AppRadius.brDialog,
          border: Border.all(color: borderColor, width: 1.2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: AppTypography.displaySm.copyWith(color: colors.ink),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                message,
                style: AppTypography.bodyMd.copyWith(color: colors.body),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: confirmLabel,
                onPressed: () => Navigator.of(context).pop(true),
                expand: true,
                backgroundColor: destructive ? colors.error : null,
                foregroundColor: destructive ? colors.onError : null,
              ),
              const SizedBox(height: AppSpacing.xs),
              // \"Cancelar\" como texto secundario debajo del botón principal.
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  cancelLabel,
                  style: AppTypography.bodyMd.copyWith(color: colors.body),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}