import 'package:flutter/material.dart';

/// Despliega su contenido hacia abajo: el hueco se abre por su borde superior
/// y el contenido se descubre ahí mismo, sin desplazarse, mientras lo que va
/// por debajo baja lo que crece. Con [open] en `false` se recoge por el mismo
/// sitio.
///
/// Es el patrón de las filas que solo tienen sentido con otro ajuste activo: la
/// que cuelga de él aparece al encenderlo.
///
/// No anima en su primer build —cuando se monta ya trae [open] y lo aplica tal
/// cual, con el resto de la pantalla—, así que para que el valor inicial no se
/// anime, el padre no debe montarlo hasta conocerlo.
class UnfoldDown extends StatefulWidget {
  const UnfoldDown({super.key, required this.open, required this.child});

  /// Con `false` el bloque queda recogido: alto cero, sin responder al toque y
  /// fuera del árbol de semántica.
  final bool open;

  final Widget child;

  @override
  State<UnfoldDown> createState() => _UnfoldDownState();
}

class _UnfoldDownState extends State<UnfoldDown>
    with SingleTickerProviderStateMixin {
  static const Duration _duration = Duration(milliseconds: 260);

  late final AnimationController _controller = AnimationController(
    duration: _duration,
    vsync: this,
    value: widget.open ? 1 : 0,
  );

  late final Animation<double> _reveal = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );

  @override
  void didUpdateWidget(covariant UnfoldDown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.open == oldWidget.open) return;
    widget.open ? _controller.forward() : _controller.reverse();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: _reveal,
      // Anclado arriba: el hueco crece hacia abajo y el contenido se descubre
      // desde arriba. El contenido no se desplaza — si lo hiciera, asomaría
      // primero su borde de abajo, que es el que no se ve venir.
      alignment: Alignment.topCenter,
      child: ExcludeSemantics(
        excluding: !widget.open,
        child: IgnorePointer(ignoring: !widget.open, child: widget.child),
      ),
    );
  }
}
