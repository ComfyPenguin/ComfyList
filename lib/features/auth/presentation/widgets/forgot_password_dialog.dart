import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/core/theme/app_radius.dart';
import '../../../../shared/core/theme/app_spacing.dart';
import '../../../../shared/core/theme/app_theme.dart';
import '../../../../shared/core/theme/app_typography.dart';
import '../../../../shared/ui/buttons/primary_button.dart';
import '../../../../shared/ui/inputs/app_text_field.dart';
import '../providers/auth_provider.dart';

/// Dialog modal para solicitar restablecimiento de contraseña.
///
/// Estados internos: [_Status.input] → [_Status.loading] → [_Status.success].
/// El mensaje final es genérico a propósito (no revela si el email existe).
class ForgotPasswordDialog extends ConsumerStatefulWidget {
  const ForgotPasswordDialog({super.key, this.initialEmail});

  final String? initialEmail;

  /// Helper para abrirlo con `showDialog`.
  static Future<void> show(BuildContext context, {String? initialEmail}) {
    return showDialog<void>(
      context: context,
      builder: (_) => ForgotPasswordDialog(initialEmail: initialEmail),
    );
  }

  @override
  ConsumerState<ForgotPasswordDialog> createState() =>
      _ForgotPasswordDialogState();
}

enum _Status { input, loading, success }

class _ForgotPasswordDialogState extends ConsumerState<ForgotPasswordDialog> {
  late final TextEditingController _emailCtrl;
  _Status _status = _Status.input;
  String? _emailError;
  String? _serverError;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.initialEmail ?? '');
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  bool _validate() {
    setState(() {
      _emailError = _emailCtrl.text.trim().contains('@')
          ? null
          : 'Introduce un correo válido.';
      _serverError = null;
    });
    return _emailError == null;
  }

  Future<void> _submit() async {
    if (!_validate()) return;
    setState(() => _status = _Status.loading);

    final result = await ref
        .read(authRepositoryProvider)
        .sendPasswordResetEmail(email: _emailCtrl.text.trim());

    if (!mounted) return;
    result.fold(
      onOk: (_) => setState(() => _status = _Status.success),
      onErr: (failure) => setState(() {
        _status = _Status.input;
        _serverError = failure.message;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = colors.canvas.computeLuminance() < 0.05;
    final borderColor = isDark
        ? colors.ink.withValues(alpha: 0.18)
        : colors.ink.withValues(alpha: 0.12);

    // Card estilo citas: fondo canvas + borde hairline + radio grande.
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
          child: _status == _Status.success
              ? _SuccessView(onClose: () => Navigator.of(context).pop())
              : _InputView(
                  emailCtrl: _emailCtrl,
                  emailError: _emailError,
                  serverError: _serverError,
                  isLoading: _status == _Status.loading,
                  onCancel: () => Navigator.of(context).pop(),
                  onSubmit: _submit,
                  bodyColor: colors.body,
                  inkColor: colors.ink,
                  errorColor: colors.error,
                ),
        ),
      ),
    );
  }
}

class _InputView extends StatelessWidget {
  const _InputView({
    required this.emailCtrl,
    required this.emailError,
    required this.serverError,
    required this.isLoading,
    required this.onCancel,
    required this.onSubmit,
    required this.bodyColor,
    required this.inkColor,
    required this.errorColor,
  });

  final TextEditingController emailCtrl;
  final String? emailError;
  final String? serverError;
  final bool isLoading;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;
  final Color bodyColor;
  final Color inkColor;
  final Color errorColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Restablecer contraseña',
          style: AppTypography.displaySm.copyWith(color: inkColor),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Te enviaremos un enlace al correo',
          style: AppTypography.bodyMd.copyWith(color: bodyColor),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),
        AppTextField(
          controller: emailCtrl,
          label: 'Correo electrónico',
          hint: 'tu@correo.com',
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSubmit(),
          errorText: emailError,
          enabled: !isLoading,
          cardStyle: true,
        ),
        if (serverError != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            serverError!,
            style: AppTypography.bodySm.copyWith(color: errorColor),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(
          label: 'Enviar',
          onPressed: onSubmit,
          isLoading: isLoading,
          expand: true,
        ),
        const SizedBox(height: AppSpacing.xs),
        // "Cancelar" como texto secundario debajo del botón principal.
        TextButton(
          onPressed: isLoading ? null : onCancel,
          style: TextButton.styleFrom(
            minimumSize: Size.zero,
            padding: const EdgeInsets.all(AppSpacing.sm),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Cancelar',
            style: AppTypography.bodyMd.copyWith(color: bodyColor),
          ),
        ),
      ],
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.mark_email_read_outlined, size: 48, color: colors.ink),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Revisa tu correo',
          style: AppTypography.displaySm.copyWith(color: colors.ink),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.md),
        // Mensaje genérico a propósito: no confirmamos si la cuenta existe
        // para evitar enumeración de cuentas registradas.
        Text.rich(
          TextSpan(
            text: 'Si el correo está registrado, recibirás un enlace para '
                'restablecer la contraseña. ',
            style: AppTypography.bodyMd.copyWith(color: colors.body),
            children: [
              TextSpan(
                text: 'Comprueba también la carpeta de spam.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),
        PrimaryButton(
          label: 'Cerrar',
          onPressed: onClose,
          expand: true,
        ),
      ],
    );
  }
}
