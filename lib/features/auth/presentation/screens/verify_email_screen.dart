import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/core/result/result.dart';
import '../../../../shared/core/theme/app_spacing.dart';
import '../../../../shared/core/theme/app_theme.dart';
import '../../../../shared/core/theme/app_typography.dart';
import '../../../../shared/ui/buttons/primary_button.dart';
import '../providers/auth_provider.dart';
import '../providers/auth_state.dart';

/// Pantalla de la sesión sin verificar. El router no deja llegar a ninguna
/// otra, así que aquí solo caben tres salidas: comprobar, reenviar o salir.
class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  bool _checking = false;
  bool _resending = false;
  String? _message;
  bool _isError = false;

  Future<void> _check() async {
    setState(() {
      _checking = true;
      _message = null;
    });

    final result = await ref.read(authProvider.notifier).checkEmailVerified();
    // Si ya está verificado, el router se lleva la pantalla por delante.
    if (!mounted) return;

    setState(() {
      _checking = false;
      switch (result) {
        case Ok(value: final verified):
          _isError = false;
          _message = verified
              ? null
              : 'Todavía no aparece como verificado. Dale al enlace y '
                  'vuelve a intentarlo.';
        case Err(failure: final failure):
          _isError = true;
          _message = failure.message;
      }
    });
  }

  Future<void> _resend() async {
    setState(() {
      _resending = true;
      _message = null;
    });

    final result =
        await ref.read(authProvider.notifier).resendVerificationEmail();
    if (!mounted) return;

    setState(() {
      _resending = false;
      switch (result) {
        case Ok():
          _isError = false;
          _message = 'Te hemos enviado otro correo.';
        case Err(failure: final failure):
          _isError = true;
          _message = failure.message;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final colors = context.colors;
    final email =
        auth is AuthUnverifiedEmail ? auth.user.email : 'tu correo';

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xxxl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset(
                    'assets/logo-face.png',
                    width: 120,
                    height: 120,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'VERIFICA',
                          style: TextStyle(color: colors.ink),
                        ),
                        TextSpan(
                          text: ' TU CORREO',
                          style: TextStyle(color: colors.muted),
                        ),
                      ],
                    ),
                    style: AppTypography.displayXl.copyWith(
                      fontFamily: 'Fredoka',
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(
                          text: 'Te hemos enviado un enlace a ',
                        ),
                        TextSpan(
                          text: email,
                          style: TextStyle(
                            color: colors.ink,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const TextSpan(
                          text: '. Ábrelo para activar la cuenta.',
                        ),
                      ],
                    ),
                    style: AppTypography.bodyMd.copyWith(color: colors.muted),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                  PrimaryButton(
                    label: 'Ya lo he verificado',
                    onPressed: _checking ? null : _check,
                    isLoading: _checking,
                    expand: true,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SecondaryAction(
                    label: 'Reenviar correo',
                    onPressed: _resending ? null : _resend,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _SecondaryAction(
                    label: 'Cerrar sesión',
                    onPressed: () => ref.read(authProvider.notifier).signOut(),
                  ),
                  if (_message != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      _message!,
                      style: AppTypography.bodySm.copyWith(
                        color: _isError ? colors.error : colors.muted,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Acción secundaria de la pantalla: texto sin relleno, centrado y atenuado
/// para no competir con el botón principal.
class _SecondaryAction extends StatelessWidget {
  const _SecondaryAction({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return TextButton(
      onPressed: onPressed,
      child: Text(
        label,
        style: AppTypography.bodySm.copyWith(
          color: onPressed == null ? colors.cardBorder : colors.muted,
        ),
      ),
    );
  }
}
