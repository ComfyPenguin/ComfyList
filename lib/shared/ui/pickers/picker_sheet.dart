import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../buttons/primary_button.dart';

/// Estructura común de los sheets de selección del DS: título centrado,
/// contenido, CTA pill y, si la selección se puede deshacer, una acción
/// secundaria debajo.
class PickerSheet extends StatelessWidget {
  const PickerSheet({
    super.key,
    required this.title,
    required this.onConfirm,
    required this.child,
    this.confirmLabel = 'Aceptar',
    this.secondaryLabel,
    this.onSecondary,
  });

  final String title;
  final VoidCallback onConfirm;
  final Widget child;
  final String confirmLabel;

  /// Acción de segundo nivel —quitar lo elegido, p. ej.—. Sin ella, el sheet
  /// se queda con el CTA solo.
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        0,
        AppSpacing.xxl,
        AppSpacing.xxxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.displaySm.copyWith(color: colors.ink),
          ),
          const SizedBox(height: AppSpacing.lg),
          child,
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: confirmLabel,
            onPressed: onConfirm,
            expand: true,
          ),
          if (secondaryLabel != null) ...[
            const SizedBox(height: AppSpacing.xs),
            TextButton(onPressed: onSecondary, child: Text(secondaryLabel!)),
          ],
        ],
      ),
    );
  }
}
