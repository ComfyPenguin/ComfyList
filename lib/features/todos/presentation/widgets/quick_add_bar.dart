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
    final isDark = colors.isDarkCanvas;

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: AppRadius.brPill,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                height: 48,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: colors.canvas.withValues(alpha: 0.7),
                  borderRadius: AppRadius.brPill,
                  border: Border.all(color: colors.cardBorder, width: 1.2),
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  textInputAction: TextInputAction.done,
                  textCapitalization: TextCapitalization.sentences,
                  textAlignVertical: TextAlignVertical.center,
                  onEditingComplete: () {},
                  onSubmitted: _submit,
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    filled: false,
                    isCollapsed: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                  ),
                ),
              ),
            ),
          ),
        ),
        // El ancho animado hace que el campo se encoja suavemente mientras
        // el botón entra, sin reconstruir/intercambiar el subárbol completo.
        AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          width: widget.showSubmitButton ? 56 : 0,
          height: 48,
          clipBehavior: Clip.none,
          child: AnimatedOpacity(
            opacity: widget.showSubmitButton ? 1 : 0,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            child: AnimatedScale(
              scale: widget.showSubmitButton ? 1 : 0.78,
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(left: AppSpacing.sm),
                child: _SubmitButton(
                  isDark: isDark,
                  onPressed: () => _submit(_controller.text),
                ),
              ),
            ),
          ),
        ),
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
        width: 48,
        height: 48,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(2),
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
                  size: 22,
                  color: isDark ? colors.canvasSofter : colors.onPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
