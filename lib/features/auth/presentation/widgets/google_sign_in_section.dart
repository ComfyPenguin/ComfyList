import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../shared/core/theme/app_spacing.dart';
import '../../../../shared/core/theme/app_theme.dart';
import '../../../../shared/core/theme/app_typography.dart';
import '../providers/auth_provider.dart';
import '../providers/auth_state.dart';

/// Divisor "o" + botón "Continuar con Google" para las pantallas de auth.
///
/// Solo se renderiza en Android en esta fase. En otras plataformas
/// devolvemos un widget vacío para que el resto del layout no se altere.
class GoogleSignInSection extends ConsumerWidget {
  const GoogleSignInSection({super.key, this.dividerText = 'o continuar con'});

  /// Texto que acompaña al divisor "o", personalizable por pantalla.
  final String dividerText;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Web no tiene dart:io.Platform; el resto sí. Mantenemos el botón oculto
    // en cualquier plataforma que no sea Android nativo.
    if (kIsWeb || !Platform.isAndroid) return const SizedBox.shrink();

    final auth = ref.watch(authProvider);
    final isLoading = auth is AuthLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.xl),
        _OrDivider(text: dividerText),
        const SizedBox(height: AppSpacing.xl),
        _GoogleButton(
          isLoading: isLoading,
          onPressed: () => ref.read(authProvider.notifier).signInWithGoogle(),
        ),
      ],
    );
  }
}

/// Línea horizontal con "o continuar con" centrado.
class _OrDivider extends StatelessWidget {
  const _OrDivider({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: colors.hairline,
            thickness: 2,
            height: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            text.toUpperCase(),
            style: AppTypography.bodySm.copyWith(
              color: colors.muted,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: colors.hairline,
            thickness: 2,
            height: 1,
          ),
        ),
      ],
    );
  }
}

/// Botón pill outline con logo G de Google a la izquierda.
/// No usamos `AppSecondaryButton` porque necesitamos un widget gráfico
/// (no IconData) para el logo multicolor.
class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/svg/google_g.svg',
              width: 18,
              height: 18,
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              'Google',
              style: AppTypography.bodyMd.copyWith(
                color: colors.ink,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
