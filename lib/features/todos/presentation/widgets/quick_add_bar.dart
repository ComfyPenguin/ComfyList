import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../shared/core/theme/app_radius.dart';
import '../../../../shared/core/theme/app_spacing.dart';
import '../../../../shared/core/theme/app_theme.dart';

/// Barra de entrada rápida estilo "lista de compra".
///
/// Un campo de texto que al pulsar Enter ejecuta [onSubmit], limpia el campo
/// y mantiene el foco para seguir añadiendo tareas sin fricción.
class QuickAddBar extends StatefulWidget {
  const QuickAddBar({
    super.key,
    required this.onSubmit,
    this.hint = 'Añadir...',
    this.showSubmitButton = false,
  });

  /// Se llama al pulsar Enter con el texto introducido (ya recortado).
  final ValueChanged<String> onSubmit;

  /// Texto de sugerencia cuando el campo está vacío.
  final String hint;

  /// Muestra el botón circular de envío junto a la barra.
  final bool showSubmitButton;

  @override
  State<QuickAddBar> createState() => _QuickAddBarState();
}

class _QuickAddBarState extends State<QuickAddBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit(String value) {
    final text = value.trim();
    if (text.isEmpty) return;

    widget.onSubmit(text);
    _controller.clear();

    // Evita que la acción Done retire el foco y haga parpadear el teclado.
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = colors.canvas.computeLuminance() < 0.05;
    final borderColor = isDark
        ? colors.ink.withValues(alpha: 0.18)
        : colors.ink.withValues(alpha: 0.12);

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: AppRadius.brPill,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                height: 52,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: colors.canvas.withValues(alpha: 0.7),
                  borderRadius: AppRadius.brPill,
                  border: Border.all(color: borderColor, width: 1.2),
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  textInputAction: TextInputAction.done,
                  textCapitalization: TextCapitalization.sentences,
                  onEditingComplete: () {},
                  onSubmitted: _submit,
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    filled: false,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (widget.showSubmitButton) ...[
          const SizedBox(width: AppSpacing.sm),
          _SubmitButton(
            isDark: isDark,
            onPressed: () => _submit(_controller.text),
          ),
        ],
      ],
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({required this.isDark, required this.onPressed});

  final bool isDark;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Tooltip(
      message: 'Añadir tarea',
      child: SizedBox(
        width: 52,
        height: 52,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Container(
            decoration: BoxDecoration(
              color: colors.primary,
              shape: BoxShape.circle,
              boxShadow: isDark
                  ? [
                      BoxShadow(
                        color: colors.primary.withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: Offset.zero,
                      ),
                      BoxShadow(
                        color: colors.shadowDark,
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: colors.shadowDark,
                        blurRadius: 16,
                        offset: const Offset(4, 8),
                      ),
                    ],
            ),
            child: Center(
              child: Icon(
                Icons.add,
                size: 28,
                color: isDark ? colors.canvasSofter : colors.onPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
