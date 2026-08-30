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
import '../widgets/forgot_password_dialog.dart';
import '../widgets/google_sign_in_section.dart';

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
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    // Restauramos el correo recordado en segundo plano para no bloquear el primer frame.
    Future.microtask(_restoreRememberedEmail);
  }

  Future<void> _restoreRememberedEmail() async {
    final store = ref.read(loginPreferencesStoreProvider);
    final email = await store.readLastEmail();
    if (!mounted) return;
    if (email != null && email.isNotEmpty && _emailCtrl.text.isEmpty) {
      setState(() => _emailCtrl.text = email);
    }
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

    // Guardamos el correo antes de delegar el sign-in: si el flujo tiene
    // éxito, GoRouter nos sacará de esta pantalla y perderíamos el setState.
    final store = ref.read(loginPreferencesStoreProvider);
    await store.saveRememberedEmail(email);

    await ref.read(authProvider.notifier).signIn(
          email: email,
          password: _passwordCtrl.text,
        );
  }

  // ─────────────────────────── build ───────────────────────────

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final colors = context.colors;

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
                  const SizedBox(height: AppSpacing.xxxxl),

                  _buildEmailCard(auth, colors),

                  if (auth is AuthError) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      auth.failure.message,
                      style: AppTypography.bodySm.copyWith(
                        color: colors.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],

                  const GoogleSignInSection(dividerText: 'O entra con'),

                  const SizedBox(height: AppSpacing.md),
                  TextButton(
                    onPressed: () => context.push(Routes.signUp),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '¿Aún no tienes cuenta? ',
                            style: TextStyle(color: colors.muted),
                          ),
                          const TextSpan(
                            text: 'Regístrate',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────── tarjeta email ───────────────────────────

  /// Formulario de email con cabecera en mayúsculas (estilo de las cabeceras
  /// de fecha de citas) y botón pill con glow.
  Widget _buildEmailCard(AuthState auth, AppColors colors) {
    final isLoading = auth is AuthLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          controller: _emailCtrl,
          label: 'Correo electrónico',
          hint: 'tu@correo.com',
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          errorText: _emailError,
          cardStyle: true,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          controller: _passwordCtrl,
          label: 'Contraseña',
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          errorText: _passwordError,
          cardStyle: true,
          suffixIcon: Padding(
            // Espaciado fuera del toggle para separarlo del borde del campo.
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: SizedBox(
              width: 36,
              height: 36,
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => setState(
                    () => _obscurePassword = !_obscurePassword,
                  ),
                  child: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 22,
                    color: colors.muted,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
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
          child: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: AppSpacing.sm),
              child: Text(
                '¿Olvidaste la contraseña?',
                style: AppTypography.bodySm.copyWith(color: colors.muted),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        // Botón pill con glow, igual que la píldora HOY de citas.
        PrimaryButton(
          label: 'Entrar',
          onPressed: _submit,
          isLoading: isLoading,
          expand: true,
        ),
      ],
    );
  }
}
