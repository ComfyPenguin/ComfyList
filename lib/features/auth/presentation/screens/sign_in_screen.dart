import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../routing/routes.dart';
import '../../../../shared/core/theme/app_radius.dart';
import '../../../../shared/core/theme/app_spacing.dart';
import '../../../../shared/core/theme/app_theme.dart';
import '../../../../shared/core/theme/app_typography.dart';
import '../../../../shared/ui/buttons/app_primary_button.dart';
import '../../../../shared/ui/inputs/app_text_field.dart';
import '../providers/auth_provider.dart';
import '../providers/auth_state.dart';
import '../widgets/forgot_password_dialog.dart';

enum _AuthMode { selector, email }

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String? _emailError;
  String? _passwordError;
  bool _rememberEmail = false;
  late _AuthMode _mode;

  bool get _hasGoogle => !kIsWeb && Platform.isAndroid;

  @override
  void initState() {
    super.initState();
    // En Android mostramos el selector de método (Google vs. correo).
    // En otras plataformas no hay Google Sign-In, así que abrimos el form directamente.
    _mode = _hasGoogle ? _AuthMode.selector : _AuthMode.email;
    // Restauramos el correo recordado en segundo plano para no bloquear el primer frame.
    Future.microtask(_restoreRememberedEmail);
  }

  Future<void> _restoreRememberedEmail() async {
    final store = ref.read(loginPreferencesStoreProvider);
    final remember = await store.readRememberEmail();
    if (!mounted || !remember) return;
    final email = await store.readLastEmail();
    if (!mounted) return;
    setState(() {
      _rememberEmail = true;
      if (email != null && email.isNotEmpty && _emailCtrl.text.isEmpty) {
        _emailCtrl.text = email;
      }
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  bool _validate() {
    setState(() {
      _emailError =
          _emailCtrl.text.contains('@') ? null : 'Introduce un correo válido.';
      _passwordError = _passwordCtrl.text.length >= 6
          ? null
          : 'La contraseña debe tener al menos 6 caracteres.';
    });
    return _emailError == null && _passwordError == null;
  }

  Future<void> _submit() async {
    if (!_validate()) return;
    final email = _emailCtrl.text.trim();

    // Guardamos la preferencia antes de delegar el sign-in: si el flujo tiene
    // éxito, GoRouter nos sacará de esta pantalla y perderíamos el setState.
    final store = ref.read(loginPreferencesStoreProvider);
    if (_rememberEmail) {
      await store.saveRememberedEmail(email);
    } else {
      await store.clearRememberedEmail();
    }

    await ref.read(authProvider.notifier).signIn(
          email: email,
          password: _passwordCtrl.text,
        );
  }

  // ─────────────────────────── build ───────────────────────────

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final isLoading = auth is AuthLoading;

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
                  // Logo centrado en lugar del título textual.
                  Center(
                    child: Image.asset(
                      'assets/logo-no-background.png',
                      width: 160,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxxl),

                  // Selector de método o formulario, con transición animada.
                  AnimatedCrossFade(
                    firstChild: _buildSelector(isLoading),
                    secondChild: _buildEmailForm(auth),
                    crossFadeState: _mode == _AuthMode.selector
                        ? CrossFadeState.showFirst
                        : CrossFadeState.showSecond,
                    duration: const Duration(milliseconds: 220),
                    sizeCurve: Curves.easeInOut,
                  ),

                  // Mensaje de error visible en ambos modos (selector y email).
                  if (auth is AuthError) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      auth.failure.message,
                      style: AppTypography.bodySm.copyWith(
                        color: context.colors.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],

                  const SizedBox(height: AppSpacing.md),
                  TextButton(
                    onPressed: () => context.push(Routes.signUp),
                    child: const Text('¿Aún no tienes cuenta? Regístrate'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────── selector ───────────────────────────

  Widget _buildSelector(bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Botón Google
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: isLoading
                ? null
                : () => ref.read(authProvider.notifier).signInWithGoogle(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  'assets/svg/google_g.svg',
                  width: 18,
                  height: 18,
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  'Continuar con Google',
                  style: AppTypography.buttonMd.copyWith(
                    color: context.colors.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // Botón correo
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: isLoading
                ? null
                : () => setState(() => _mode = _AuthMode.email),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.mail_outline, size: 18),
                const SizedBox(width: AppSpacing.md),
                Text(
                  'Continuar con correo',
                  style: AppTypography.buttonMd.copyWith(
                    color: context.colors.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────── formulario email ───────────────────────────

  Widget _buildEmailForm(AuthState auth) {
    final colors = context.colors;
    final isLoading = auth is AuthLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        // Espacio para que el FloatingLabel no quede cortado por el clip
        // interno del AnimatedCrossFade cuando el campo recibe foco.
        const SizedBox(height: AppSpacing.sm),
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
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          errorText: _passwordError,
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            _RememberEmailCheckbox(
              value: _rememberEmail,
              onChanged: (v) => setState(() => _rememberEmail = v),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => ForgotPasswordDialog.show(
                context,
                initialEmail: _emailCtrl.text.trim(),
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                '¿Olvidaste la contraseña?',
                style: AppTypography.bodySm.copyWith(color: colors.muted),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        AppPrimaryButton(
          label: 'Entrar',
          onPressed: _submit,
          isLoading: isLoading,
          expand: true,
        ),
        // Solo en Android: enlace para volver a elegir método.
        if (_hasGoogle) ...[
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: TextButton(
              onPressed: isLoading
                  ? null
                  : () => setState(() => _mode = _AuthMode.selector),
              child: const Text('← Usar otro método'),
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────── helper widgets ───────────────────────────

/// Fila Checkbox + label. Pulsando el texto también alterna el valor —
/// el área de tap útil cubre ambos, no solo el cuadrado del checkbox.
class _RememberEmailCheckbox extends StatelessWidget {
  const _RememberEmailCheckbox({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: AppRadius.brMd,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: value,
                onChanged: (v) => onChanged(v ?? false),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Recordar mi correo',
              style: AppTypography.bodyMd.copyWith(color: colors.ink),
            ),
          ],
        ),
      ),
    );
  }
}
