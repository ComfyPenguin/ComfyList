import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../routing/routes.dart';
import '../../../../shared/core/theme/app_spacing.dart';
import '../../../../shared/core/theme/app_theme.dart';
import '../../../../shared/core/theme/app_typography.dart';
import '../../../../shared/ui/buttons/primary_button.dart';
import '../../../../shared/ui/inputs/app_text_field.dart';
import '../../domain/entities/email_policy.dart';
import '../../domain/entities/password_policy.dart';
import '../providers/auth_provider.dart';
import '../providers/auth_state.dart';
import '../widgets/google_sign_in_section.dart';
import '../widgets/password_rules_checklist.dart';

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
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _passwordConfirmCtrl.dispose();
    super.dispose();
  }

  bool _validate() {
    setState(() {
      _emailError = EmailPolicy.isValid(_emailCtrl.text)
          ? null
          : 'Introduce un correo válido.';
      _passwordError = PasswordPolicy.isValid(_passwordCtrl.text)
          ? null
          : 'La contraseña no cumple los requisitos.';
      _confirmError = _passwordConfirmCtrl.text == _passwordCtrl.text
          ? null
          : 'Las contraseñas no coinciden.';
    });
    return _emailError == null &&
        _passwordError == null &&
        _confirmError == null;
  }

  /// Toggle circular de visibilidad de la contraseña (mismo estilo que el
  /// login, con espaciado exterior para separarlo del borde del campo).
  Widget _buildVisibilityToggle({
    required bool obscure,
    required VoidCallback onToggle,
    required AppColors colors,
  }) {
    return Padding(
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
            onTap: onToggle,
            child: Icon(
              obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              size: 22,
              color: colors.muted,
            ),
          ),
        ),
      ),
    );
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
                  // Logo de la app encima del título.
                  Image.asset(
                    'assets/logo-face.png',
                    width: 120,
                    height: 120,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // Título de la pantalla de registro bicolor (igual que el login).
                  // Ocupa el mismo ancho que los campos del formulario.
                  SizedBox(
                    width: double.infinity,
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'REGÍSTRATE',
                            style: TextStyle(color: colors.ink),
                          ),
                          TextSpan(
                            text: ' AHORA',
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
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                  AppTextField(
                    controller: _emailCtrl,
                    label: 'Correo electrónico',
                    hint: 'tu@correo.com',
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    // Si se borra el correo se eliminan también las
                    // contraseñas para ocultar sus campos de nuevo.
                    onChanged: (_) {
                      if (_emailCtrl.text.trim().isEmpty) {
                        _passwordCtrl.clear();
                        _passwordConfirmCtrl.clear();
                        _emailError = null;
                        _passwordError = null;
                        _confirmError = null;
                      }
                      setState(() {});
                    },
                    errorText: _emailError,
                    cardStyle: true,
                  ),
                  // Los campos siguientes aparecen con un slide desde el campo
                  // superior al rellenar el anterior.
                  _RevealSlide(
                    visible: _emailCtrl.text.trim().isNotEmpty,
                    child: Column(
                      children: [
                        AppTextField(
                          controller: _passwordCtrl,
                          label: 'Contraseña',
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.next,
                          // Si se borra la contraseña se elimina también la
                          // confirmación para ocultar ese campo de nuevo.
                          onChanged: (_) {
                            if (_passwordCtrl.text.isEmpty) {
                              _passwordConfirmCtrl.clear();
                              _confirmError = null;
                            }
                            // Con los requisitos a la vista, dejar el aviso
                            // rojo cuando ya se cumplen sobra: se limpia solo.
                            if (_passwordError != null &&
                                PasswordPolicy.isValid(_passwordCtrl.text)) {
                              _passwordError = null;
                            }
                            setState(() {});
                          },
                          errorText: _passwordError,
                          cardStyle: true,
                          suffixIcon: _buildVisibilityToggle(
                            obscure: _obscurePassword,
                            onToggle: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                            colors: colors,
                          ),
                        ),
                        _RevealSlide(
                          visible: _passwordCtrl.text.isNotEmpty,
                          child: PasswordRulesChecklist(
                            password: _passwordCtrl.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _RevealSlide(
                    visible: _passwordCtrl.text.isNotEmpty,
                    child: AppTextField(
                      controller: _passwordConfirmCtrl,
                      label: 'Repite la contraseña',
                      obscureText: _obscureConfirm,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      errorText: _confirmError,
                      cardStyle: true,
                      suffixIcon: _buildVisibilityToggle(
                        obscure: _obscureConfirm,
                        onToggle: () => setState(
                          () => _obscureConfirm = !_obscureConfirm,
                        ),
                        colors: colors,
                      ),
                    ),
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
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '¿Ya tienes cuenta? ',
                            style: TextStyle(color: colors.muted),
                          ),
                          const TextSpan(
                            text: 'Inicia sesión',
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
}

/// Envoltorio que muestra [child] con un slide desde el campo superior + fade
/// cuando [visible] pasa a `true`. Cuando se oculta, se colapsa sin dejar
/// hueco (la altura anima con el propio slide).
class _RevealSlide extends StatelessWidget {
  const _RevealSlide({required this.visible, required this.child});

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: AnimatedAlign(
        alignment: Alignment.topCenter,
        heightFactor: visible ? 1 : 0,
        curve: Curves.easeOutCubic,
        duration: const Duration(milliseconds: 350),
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          curve: Curves.easeOut,
          duration: const Duration(milliseconds: 250),
          child: FractionalTranslation(
            translation: visible
                ? Offset.zero
                : const Offset(0, -0.4), // desliza desde arriba (campo previo)
            child: IgnorePointer(
              ignoring: !visible,
              child: Padding(
                // Espaciado que antes daba el SizedBox entre campos.
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
