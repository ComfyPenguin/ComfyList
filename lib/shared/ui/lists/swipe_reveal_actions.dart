import 'package:flutter/material.dart';

/// Acción revelable bajo un swipe horizontal.
class SwipeRevealAction {
  const SwipeRevealAction({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  /// Widget que se muestra dentro del botón revelado (típicamente un
  /// [Icon] o un `Lottie.asset`). El caller controla su tamaño.
  final Widget icon;

  /// Texto para lectores de pantalla y tooltip.
  final String label;

  final Color background;
  final Color foreground;
  final VoidCallback onTap;
}

/// Patrón "slide to reveal" bidireccional: el hijo se traslada
/// horizontalmente hasta el 25 % del ancho revelando una acción detrás.
/// - [leftAction] aparece deslizando a la DERECHA.
/// - [rightAction] aparece deslizando a la IZQUIERDA.
///
/// No es Dismissible — la acción solo se ejecuta al pulsar el botón
/// revelado, y se ejecuta directamente (si hace falta confirmación,
/// debe pedirla el caller dentro del [SwipeRevealAction.onTap]).
class SwipeRevealActions extends StatefulWidget {
  const SwipeRevealActions({
    super.key,
    required this.child,
    this.leftAction,
    this.rightAction,
    this.onRevealProgressChanged,
    this.onRightRevealProgressChanged,
    this.onLeftRevealProgressChanged,
    this.actionOverlap = 24,
    this.actionBorderRadius,
  });

  final Widget child;
  final SwipeRevealAction? leftAction;
  final SwipeRevealAction? rightAction;

  /// Solape bajo la card para que el atajo quede pegado a bordes redondeados.
  final double actionOverlap;

  /// Radio del fondo de los atajos. Útil cuando el contenedor exterior no recorta.
  final BorderRadius? actionBorderRadius;

  /// Progreso absoluto del swipe: 0 cerrado, 1 atajo totalmente revelado.
  final ValueChanged<double>? onRevealProgressChanged;

  /// Progreso signed del lado derecho: 0 cerrado, valores negativos de 0 a -1
  /// según se revela el atajo. Útil para disparar efectos solo cuando se abre
  /// la acción derecha (p. ej. reproducir un Lottie una sola vez por reveal).
  final ValueChanged<double>? onRightRevealProgressChanged;

  /// Progreso signed del lado izquierdo: 0 cerrado, valores positivos de 0 a 1
  /// según se revela el atajo. Simétrico al derecho, para efectos asociados a
  /// la acción izquierda.
  final ValueChanged<double>? onLeftRevealProgressChanged;

  @override
  State<SwipeRevealActions> createState() => _SwipeRevealActionsState();
}

class _SwipeRevealActionsState extends State<SwipeRevealActions>
    with SingleTickerProviderStateMixin {
  // Porcentaje del ancho que se desliza para revelar el botón.
  static const double _revealRatio = 0.25;
  // Velocidad (px/s) por encima de la cual el fling decide la dirección.
  static const double _flingThreshold = 700;
  // Desde cerrado hay que revelar bastante antes de dejar el atajo abierto.
  static const double _openThreshold = 0.62;
  // Desde abierto se puede cerrar con un arrastre más corto en sentido contrario.
  static const double _retainOpenThreshold = 0.76;
  // Evita que un gesto cambie de editar a borrar, o viceversa, a mitad de drag.
  static const double _directionLockThreshold = 0.04;
  static const double _visibleThreshold = 0.01;

  late final AnimationController _ctrl;
  double _maxWidth = 0;
  double _lastNotifiedProgress = 0;
  int _gestureDirection = 0;
  bool _dragStartedOpen = false;

  @override
  void initState() {
    super.initState();
    // El valor del controller representa el desplazamiento normalizado del
    // hijo: positivo = derecha (revela leftAction), negativo = izquierda
    // (revela rightAction), 0 = cerrado.
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
      lowerBound: -1.0,
      upperBound: 1.0,
      value: 0.0,
    )..addListener(_notifyRevealProgress);
  }

  @override
  void dispose() {
    _ctrl
      ..removeListener(_notifyRevealProgress)
      ..dispose();
    super.dispose();
  }

  double get _revealWidth => _maxWidth * _revealRatio;

  // Solo permitimos abrir el lado que tenga acción asociada.
  double get _minValue => widget.rightAction != null ? -1.0 : 0.0;
  double get _maxValue => widget.leftAction != null ? 1.0 : 0.0;

  void _notifyRevealProgress() {
    final value = _ctrl.value;
    final progress = value.abs().clamp(0.0, 1.0).toDouble();
    final isResting = progress == 0 || progress == 1;
    if ((progress - _lastNotifiedProgress).abs() < 0.01 && !isResting) {
      return;
    }

    _lastNotifiedProgress = progress;
    widget.onRevealProgressChanged?.call(progress);
    // Progreso derecho normalizado a 0..-1; 0 si está cerrado o se revela
    // el lado izquierdo, para que el listener solo vea el lado que le importa.
    widget.onRightRevealProgressChanged
        ?.call(value < 0 ? value.clamp(-1.0, 0.0) : 0.0);
    // Progreso izquierdo normalizado a 0..1; 0 si está cerrado o se revela
    // el lado derecho.
    widget.onLeftRevealProgressChanged
        ?.call(value > 0 ? value.clamp(0.0, 1.0) : 0.0);
  }

  int _directionFor(double value) {
    if (value > _visibleThreshold) return 1;
    if (value < -_visibleThreshold) return -1;
    return 0;
  }

  void _onDragStart(DragStartDetails details) {
    _ctrl.stop();
    _gestureDirection = _directionFor(_ctrl.value);
    _dragStartedOpen = _ctrl.value.abs() >= _openThreshold;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_revealWidth == 0) return;

    final delta = details.primaryDelta ?? 0;
    final proposed = _ctrl.value + delta / _revealWidth;

    if (_gestureDirection == 0 && proposed.abs() >= _directionLockThreshold) {
      _gestureDirection = proposed > 0 ? 1 : -1;
    }

    final next = switch (_gestureDirection) {
      1 => proposed.clamp(0.0, _maxValue),
      -1 => proposed.clamp(_minValue, 0.0),
      _ => proposed.clamp(_minValue, _maxValue),
    };

    _ctrl.value = next.toDouble();
  }

  void _onDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final direction = _directionFor(_ctrl.value);
    final threshold = _dragStartedOpen ? _retainOpenThreshold : _openThreshold;

    if (direction > 0) {
      if (velocity < -_flingThreshold) {
        _settleTo(0);
      } else if (velocity > _flingThreshold && widget.leftAction != null) {
        _settleTo(1);
      } else {
        _settleTo(_ctrl.value.abs() >= threshold ? 1 : 0);
      }
    } else if (direction < 0) {
      if (velocity > _flingThreshold) {
        _settleTo(0);
      } else if (velocity < -_flingThreshold && widget.rightAction != null) {
        _settleTo(-1);
      } else {
        _settleTo(_ctrl.value.abs() >= threshold ? -1 : 0);
      }
    } else {
      _settleTo(0);
    }

    _gestureDirection = 0;
    _dragStartedOpen = false;
  }

  void _settleTo(double target) {
    _ctrl.animateTo(
      target,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  void _close() => _settleTo(0);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _maxWidth = constraints.maxWidth;
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (context, child) {
            final value = _ctrl.value;
            final leftRevealed = value > _visibleThreshold;
            final rightRevealed = value < -_visibleThreshold;
            final anyRevealed = leftRevealed || rightRevealed;
            return Stack(
              children: [
                // Acción izquierda — se ve cuando el hijo se desplaza a la derecha.
                if (widget.leftAction != null)
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: _revealWidth + widget.actionOverlap,
                        child: _ActionButton(
                          action: widget.leftAction!,
                          enabled: leftRevealed,
                          side: _ActionSide.left,
                          borderRadius: widget.actionBorderRadius,
                          contentPadding: EdgeInsets.only(
                            right: widget.actionOverlap,
                          ),
                        ),
                      ),
                    ),
                  ),
                // Acción derecha — se ve cuando el hijo se desplaza a la izquierda.
                if (widget.rightAction != null)
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        width: _revealWidth + widget.actionOverlap,
                        child: _ActionButton(
                          action: widget.rightAction!,
                          enabled: rightRevealed,
                          side: _ActionSide.right,
                          borderRadius: widget.actionBorderRadius,
                          contentPadding: EdgeInsets.only(
                            left: widget.actionOverlap,
                          ),
                        ),
                      ),
                    ),
                  ),
                // Card content trasladada según el progreso del swipe.
                Transform.translate(
                  offset: Offset(value * _revealWidth, 0),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragStart: _onDragStart,
                    onHorizontalDragUpdate: _onDragUpdate,
                    onHorizontalDragEnd: _onDragEnd,
                    // Si hay algún lado abierto, pulsar la card la cierra en
                    // vez de entrar en el detalle; bloqueamos los taps del
                    // hijo con IgnorePointer para que no compita el InkWell.
                    onTap: anyRevealed ? _close : null,
                    child: IgnorePointer(ignoring: anyRevealed, child: child),
                  ),
                ),
              ],
            );
          },
          child: widget.child,
        );
      },
    );
  }
}

enum _ActionSide { left, right }

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.action,
    required this.enabled,
    required this.side,
    required this.contentPadding,
    this.borderRadius,
  });

  final SwipeRevealAction action;
  final bool enabled;
  final _ActionSide side;
  final EdgeInsetsGeometry contentPadding;
  final BorderRadius? borderRadius;

  BorderRadius? get _outerBorderRadius {
    final radius = borderRadius;
    if (radius == null) return null;

    return switch (side) {
      _ActionSide.left => BorderRadius.only(
        topLeft: radius.topLeft,
        bottomLeft: radius.bottomLeft,
      ),
      _ActionSide.right => BorderRadius.only(
        topRight: radius.topRight,
        bottomRight: radius.bottomRight,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final outerBorderRadius = _outerBorderRadius;
    return IgnorePointer(
      ignoring: !enabled,
      child: ExcludeSemantics(
        excluding: !enabled,
        child: Tooltip(
          message: action.label,
          child: Semantics(
            button: true,
            label: action.label,
            child: Material(
              color: action.background,
              shape: outerBorderRadius == null
                  ? null
                  : RoundedRectangleBorder(borderRadius: outerBorderRadius),
              clipBehavior: outerBorderRadius == null
                  ? Clip.none
                  : Clip.antiAlias,
              child: InkWell(
                onTap: enabled ? action.onTap : null,
                child: Padding(
                  padding: contentPadding,
                  child: Center(
                    child: IconTheme.merge(
                      data: IconThemeData(color: action.foreground, size: 24),
                      child: action.icon,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
