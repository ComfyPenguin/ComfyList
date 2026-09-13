import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_stroke.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import 'field_notch.dart';

/// Campo de texto del DS — usa `inputDecorationTheme` del `AppTheme`
/// (DESIGN.md `text-input`).
///
/// Con [cardStyle] se renderiza como una card de citas (fondo `canvas`,
/// borde hairline y radio grande) en lugar del input soft por defecto.
///
/// La etiqueta va en negrita y mayúsculas solo cuando flota al borde; dentro
/// del campo (vacío y sin foco) se queda como el resto de placeholders.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.obscureText = false,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.maxLines = 1,
    this.cardStyle = false,
    this.suffixIcon,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? errorText;
  final bool obscureText;
  final TextInputType? keyboardType;

  /// Estado inicial de mayúsculas del teclado (p. ej. [TextCapitalization.sentences]
  /// en campos de texto libre).
  final TextCapitalization textCapitalization;

  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final int maxLines;

  /// Renderiza el campo como una card de citas (radio grande + borde hairline).
  final bool cardStyle;

  /// Icono opcional al final del campo (p. ej. toggle de visibilidad).
  final Widget? suffixIcon;

  /// Radio de la card del campo — espejo de las cards de citas.
  static const double _cardRadius = 32;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  /// Nodo propio para seguir el foco: la etiqueta sube al borde con el foco o
  /// con contenido (`FloatingLabelBehavior.auto`), y ahí cambia de estilo.
  final _focusNode = FocusNode();
  bool _hasText = false;

  bool get _labelFloats => _focusNode.hasFocus || _hasText;

  /// Dentro del campo va la etiqueta completa; en el borde solo sube el título
  /// y en mayúsculas — Flutter no tiene `text-transform`, así que el texto se
  /// compone según el estado.
  String? get _labelText {
    final label = widget.label;
    if (label == null) return null;
    return _labelFloats ? _floatingTitle(label).toUpperCase() : label;
  }

  /// En el borde no sube el matiz entre paréntesis: «Notas (opcional)» queda en
  /// «NOTAS».
  static String _floatingTitle(String label) {
    final title = label.replaceFirst(RegExp(r'\s*\(.*\)$'), '');
    return title.isEmpty ? label : title;
  }

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChanged);
    widget.controller?.addListener(_handleControllerChanged);
    _hasText = widget.controller?.text.isNotEmpty ?? false;
  }

  @override
  void didUpdateWidget(AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    oldWidget.controller?.removeListener(_handleControllerChanged);
    widget.controller?.addListener(_handleControllerChanged);
    _hasText = widget.controller?.text.isNotEmpty ?? false;
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_handleControllerChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChanged() => setState(() {});

  void _handleControllerChanged() {
    _setHasText(widget.controller!.text.isNotEmpty);
  }

  void _handleChanged(String value) {
    _setHasText(value.isNotEmpty);
    widget.onChanged?.call(value);
  }

  /// Reconstruye solo al cambiar de estado, no en cada pulsación.
  void _setHasText(bool hasText) {
    if (hasText == _hasText) return;
    setState(() => _hasText = hasText);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final baseDecoration = InputDecoration(
      labelText: _labelText,
      hintText: widget.hint,
      errorText: widget.errorText,
    );

    if (!widget.cardStyle) {
      return TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        obscureText: widget.obscureText,
        keyboardType: widget.keyboardType,
        textCapitalization: widget.textCapitalization,
        textInputAction: widget.textInputAction,
        inputFormatters: widget.inputFormatters,
        onChanged: _handleChanged,
        onSubmitted: widget.onSubmitted,
        enabled: widget.enabled,
        maxLines: widget.obscureText ? 1 : widget.maxLines,
        decoration: baseDecoration.copyWith(suffixIcon: widget.suffixIcon),
      );
    }

    final cardDecoration = baseDecoration.copyWith(
      filled: true,
      fillColor: colors.canvas,
      // Con contenido dentro la label flota hacia el borde: añadimos
      // padding vertical para que el campo respire dentro de la card.
      contentPadding: FieldStyle.padding,
      labelStyle: AppTypography.bodySm.copyWith(color: colors.body),
      floatingLabelStyle: AppTypography.fieldLabel(colors.ink),
      hintStyle: AppTypography.bodyMd.copyWith(color: colors.mutedSoft),
      suffixIcon: widget.suffixIcon,
      border: _outline(colors.cardBorder),
      enabledBorder: _outline(colors.cardBorder),
      focusedBorder: _outline(colors.ink, width: 1.5),
      errorBorder: _outline(colors.error),
      focusedErrorBorder: _outline(colors.error, width: 1.5),
    );

    return TextField(
      controller: widget.controller,
      focusNode: _focusNode,
      obscureText: widget.obscureText,
      keyboardType: widget.keyboardType,
      textCapitalization: widget.textCapitalization,
      textInputAction: widget.textInputAction,
      inputFormatters: widget.inputFormatters,
      onChanged: _handleChanged,
      onSubmitted: widget.onSubmitted,
      enabled: widget.enabled,
      maxLines: widget.obscureText ? 1 : widget.maxLines,
      decoration: cardDecoration,
    );
  }

  OutlineInputBorder _outline(
    Color color, {
    double width = AppStroke.hairline,
  }) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTextField._cardRadius),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
