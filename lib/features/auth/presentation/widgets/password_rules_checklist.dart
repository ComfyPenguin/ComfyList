import 'package:flutter/material.dart';

import '../../../../shared/core/theme/app_spacing.dart';
import '../../../../shared/core/theme/app_theme.dart';
import '../../../../shared/core/theme/app_typography.dart';
import '../../domain/entities/password_policy.dart';

/// Requisitos de la contraseña, marcándose según se escribe.
///
/// Enseñarlos en vivo evita el rebote de enviar el formulario para descubrir
/// qué faltaba, que en un móvil cuesta más que leer una lista de tres líneas.
class PasswordRulesChecklist extends StatelessWidget {
  const PasswordRulesChecklist({super.key, required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final rule in PasswordRule.values)
          _RuleRow(rule: rule, met: rule.isMetBy(password), colors: colors),
      ],
    );
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({
    required this.rule,
    required this.met,
    required this.colors,
  });

  final PasswordRule rule;
  final bool met;
  final AppColors colors;

  String get _label => switch (rule) {
    PasswordRule.minLength => 'Al menos ${PasswordPolicy.minLength} caracteres',
    PasswordRule.letter => 'Al menos una letra',
    PasswordRule.number => 'Al menos un número',
  };

  @override
  Widget build(BuildContext context) {
    final color = met ? colors.success : colors.muted;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 16,
            color: color,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              _label,
              style: AppTypography.caption.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
