import 'dart:async';

import 'package:flutter/material.dart';

/// Una fila del [SlideFlow]: contenido, clave y separación tras ella.
class SlideRow {
  const SlideRow({
    required this.key,
    required this.child,
    this.spacingAfter = 0,
  });

  final Key key;
  final Widget child;
  final double spacingAfter;
}

/// Flujo vertical que anima cada fila deslizándose a su nueva posición
/// cuando cambia el orden de [rows] entre builds (mismas claves, distinto
/// orden). Se usa en listas que reordenan items al completarse.
///
/// Las alturas de las filas se miden durante el layout; hasta que una fila
/// se mide usa [defaultExtent] como estimación. No es perezoso: todas las
/// filas están montadas para poder animar sus posiciones.
class SlideFlow extends StatefulWidget {
  const SlideFlow({
    super.key,
    required this.rows,
    this.duration = const Duration(milliseconds: 360),
    this.curve = Curves.easeInOutCubic,
    this.defaultExtent = 88,
  });

  final List<SlideRow> rows;
  final Duration duration;
  final Curve curve;

  /// Estimación de altura para filas aún no medidas (primer frame).
  final double defaultExtent;

  @override
  State<SlideFlow> createState() => _SlideFlowState();
}

class _SlideFlowState extends State<SlideFlow> {
  final _extents = <Key, double>{};
  List<Key>? _previousKeys;
  List<Key>? _orderBeforeMove;
  bool _animateMoves = false;
  Timer? _clearTimer;

  @override
  void didUpdateWidget(SlideFlow oldWidget) {
    super.didUpdateWidget(oldWidget);
    final previous = _previousKeys;
    if (previous == null) return;

    final next = [for (final row in widget.rows) row.key];
    if (_sameKeySet(previous, next) && !_sameKeyOrder(previous, next)) {
      _orderBeforeMove = previous;
      _animateMoves = true;
      _clearTimer?.cancel();
      _clearTimer = Timer(widget.duration, () {
        if (mounted) setState(() => _animateMoves = false);
      });
    }
  }

  @override
  void dispose() {
    _clearTimer?.cancel();
    super.dispose();
  }

  bool _sameKeySet(List<Key> a, List<Key> b) {
    if (a.length != b.length) return false;
    final bSet = b.toSet();
    for (final key in a) {
      if (!bSet.contains(key)) return false;
    }
    return true;
  }

  bool _sameKeyOrder(List<Key> a, List<Key> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _reportExtent(Key key, double extent) {
    final previous = _extents[key];
    if (previous == extent) return;
    setState(() => _extents[key] = extent);
  }

  @override
  Widget build(BuildContext context) {
    final rows = widget.rows;
    final currentKeys = [for (final row in rows) row.key];

    // Calcular la cota superior de cada fila con las alturas medidas.
    final tops = <double>[];
    var top = 0.0;
    for (final row in rows) {
      tops.add(top);
      top += (_extents[row.key] ?? widget.defaultExtent) + row.spacingAfter;
    }

    final duration = _animateMoves ? widget.duration : Duration.zero;

    // Construir filas en orden de pintado: durante el movimiento, la fila
    // desplazada se pinta la última para deslizarse por encima de las demás.
    final byKey = {for (final row in rows) row.key: row};
    final movedKey = _animateMoves && _orderBeforeMove != null
        ? _movedKey(_orderBeforeMove!, currentKeys)
        : null;
    _orderBeforeMove = null;
    _previousKeys = currentKeys;

    final paintOrder = [...rows];
    if (movedKey != null) {
      paintOrder
        ..removeWhere((row) => row.key == movedKey)
        ..add(byKey[movedKey]!);
    }

    final children = <Widget>[];
    for (final row in paintOrder) {
      final indexInRows = rows.indexOf(row);
      children.add(
        _AnimatedFlowPosition(
          key: row.key,
          top: tops[indexInRows],
          duration: duration,
          curve: widget.curve,
          onSize: (extent) => _reportExtent(row.key, extent),
          child: row.child,
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: top,
      child: Stack(
        clipBehavior: Clip.none,
        children: children,
      ),
    );
  }

  /// Clave de la fila que más ha cambiado de índice (la que se arrastra).
  Key? _movedKey(List<Key> previous, List<Key> next) {
    final nextIndex = {for (var i = 0; i < next.length; i++) next[i]: i};
    Key? best;
    var bestDelta = 0;
    for (var i = 0; i < previous.length; i++) {
      final delta = (nextIndex[previous[i]] ?? i) - i;
      if (delta.abs() > bestDelta) {
        bestDelta = delta.abs();
        best = previous[i];
      }
    }
    return best;
  }
}

/// Posiciona la fila en el flujo; anima el cambio de [top] durante un
/// reordenado y mide la altura real del hijo para el cálculo de cotas.
class _AnimatedFlowPosition extends StatelessWidget {
  const _AnimatedFlowPosition({
    super.key,
    required this.top,
    required this.duration,
    required this.curve,
    required this.onSize,
    required this.child,
  });

  final double top;
  final Duration duration;
  final Curve curve;
  final ValueChanged<double> onSize;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: duration,
      curve: curve,
      top: top,
      left: 0,
      right: 0,
      child: _SizeReporter(onSize: onSize, child: child),
    );
  }
}

class _SizeReporter extends StatefulWidget {
  const _SizeReporter({required this.onSize, required this.child});

  final ValueChanged<double> onSize;
  final Widget child;

  @override
  State<_SizeReporter> createState() => _SizeReporterState();
}

class _SizeReporterState extends State<_SizeReporter> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(_measure);
  }

  @override
  void didUpdateWidget(_SizeReporter oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback(_measure);
  }

  void _measure(Duration _) {
    if (!mounted) return;
    final size = context.size;
    if (size != null) widget.onSize(size.height);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
