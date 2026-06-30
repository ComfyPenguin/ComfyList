import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../routing/routes.dart';
import '../../../../shared/core/theme/app_spacing.dart';
import '../../../../shared/core/theme/app_theme.dart';
import '../../../../shared/core/theme/app_typography.dart';
import '../../../../shared/ui/buttons/primary_button.dart';
import '../../../../shared/ui/inputs/app_text_field.dart';
import '../providers/auth_provider.dart';
import '../providers/auth_state.dart';
import '../widgets/google_sign_in_section.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _passwordConfirmCtrl = TextEditingController();
  String? _emailError;
  String? _passwordError;
  String? _confirmError;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _passwordConfirmCtrl.dispose();
    super.dispose();
  }

  bool _validate() {
    setState(() {
      _emailError =
          _emailCtrl.text.contains('@') ? null : 'Introduce un correo válido.';
      _passwordError = _passwordCtrl.text.length >= 6
          ? null
          : 'La contraseña debe tener al menos 6 caracteres.';
      _confirmError = _passwordConfirmCtrl.text == _passwordCtrl.text
          ? null
          : 'Las contraseñas no coinciden.';
    });
    return _emailError == null &&
        _passwordError == null &&
        _confirmError == null;
  }

  Future<void> _submit() async {
    if (!_validate()) return;
    await ref.read(authProvider.notifier).signUp(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final colors = context.colors;
    final isLoading = auth is AuthLoading;
    final error = auth is AuthError ? auth.failure.message : null;

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
                  Text(
                    'Crea tu cuenta',
                    style: AppTypography.displayXl.copyWith(color: colors.ink),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Tu lista de tareas siempre contigo, en todos tus dispositivos.',
                    style: AppTypography.bodyMd.copyWith(color: colors.body),
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                  AppTextField(
                    controller: _emailCtrl,
                    label: 'Correo electrónico',
                    hint: 'tu@correo.com',
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    errorText: _emailError,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _passwordCtrl,
                    label: 'Contraseña',
                    obscureText: true,
                    textInputAction: TextInputAction.next,
                    errorText: _passwordError,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _passwordConfirmCtrl,
                    label: 'Repite la contraseña',
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                    errorText: _confirmError,
                  ),
                  if (error != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      error,
                      style: AppTypography.bodySm.copyWith(color: colors.error),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xxl),
                  PrimaryButton(
                    label: 'Crear cuenta',
                    onPressed: _submit,
                    isLoading: isLoading,
                    expand: true,
                  ),
                  const GoogleSignInSection(),
                  const SizedBox(height: AppSpacing.md),
                  TextButton(
                    onPressed: () => context.go(Routes.signIn),
                    child: const Text('¿Ya tienes cuenta? Inicia sesión'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
