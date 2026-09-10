import 'package:flutter/material.dart';

import '../../../../shared/core/theme/app_spacing.dart';

/// Barra de entrada rápida estilo "lista de compra".
///
/// Un campo de texto que al pulsar Enter ejecuta [onSubmit] con el texto,
/// limpia el campo y mantiene el foco para seguir añadiendo tareas sin
/// fricción. Ideal para flujos de captura rápida donde el usuario quiere
/// volcar muchas ideas seguidas sin navegar a otra pantalla.
class QuickAddBar extends StatefulWidget {
  const QuickAddBar({
    super.key,
    required this.onSubmit,
    this.hint = 'Añadir...',
  });

  /// Se llama al pulsar Enter con el texto introducido (ya recortado).
  /// Solo se invoca si el texto no está vacío.
  final ValueChanged<String> onSubmit;

  /// Texto de sugerencia cuando el campo está vacío.
  final String hint;

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

    // Re-solicitamos el foco en el siguiente frame para que el teclado no
    // se cierre al procesar el onSubmitted. Sin esto, en iOS y algunos
    // teclados Android el TextInputAction.done cierra el teclado antes de
    // que podamos re-enfocar.
    Future.microtask(() => _focusNode.requestFocus());
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      textInputAction: TextInputAction.done,
      textCapitalization: TextCapitalization.sentences,
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
    );
  }
}
