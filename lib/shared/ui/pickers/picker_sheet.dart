import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../buttons/primary_button.dart';

/// Estructura común de los sheets de selección del DS: título centrado, el
/// contenido y, si hay algo que confirmar, el CTA pill debajo.
class PickerSheet extends StatelessWidget {
  const PickerSheet({
    super.key,
    required this.title,
    required this.child,
    this.onConfirm,
    this.confirmLabel = 'Aceptar',
  });

  final String title;
  final Widget child;

  /// Sin [onConfirm] no hay CTA: el sheet es un menú y se elige tocando el
  /// contenido.
  final VoidCallback? onConfirm;
  final String confirmLabel;

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
          if (onConfirm != null) ...[
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: confirmLabel,
              onPressed: onConfirm!,
              expand: true,
            ),
          ],
        ],
      ),
    );
  }
}
