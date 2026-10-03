import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Texto con tachado animado: al pasar [done] a true la línea se dibuja
/// sobre el texto (y el color interpola hacia [doneColor]); al volver a
/// false la línea se retira. El trazo crece de izquierda a derecha en
/// cada línea, por lo que también funciona con títulos que ocupan varias.
class AnimatedStrikethroughText extends StatefulWidget {
  const AnimatedStrikethroughText({
    super.key,
    required this.text,
    required this.style,
    required this.done,
    this.doneColor,
    this.duration = const Duration(milliseconds: 450),
    this.maxLines,
    this.overflow,
    this.textAlign,
  });

  final String text;
  final TextStyle style;
  final bool done;
  final Color? doneColor;
  final Duration duration;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  @override
  State<AnimatedStrikethroughText> createState() =>
      _AnimatedStrikethroughTextState();
}

class _AnimatedStrikethroughTextState extends State<AnimatedStrikethroughText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  /// Progreso del tachado: 0 sin línea, 1 totalmente tachado.
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: widget.done ? 1 : 0,
    );
    _progress = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutCubic);
  }

  @override
  void didUpdateWidget(AnimatedStrikethroughText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.done != oldWidget.done) {
      _ctrl.duration = widget.duration;
      _ctrl.animateTo(widget.done ? 1 : 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.style.color ?? context.colors.ink;
    final doneColor = widget.doneColor ?? context.colors.muted;

    return AnimatedBuilder(
      animation: _progress,
      builder: (context, _) {
        final t = _progress.value;
        final color = Color.lerp(baseColor, doneColor, t)!;

        return Stack(
          children: [
            Text(
              widget.text,
              style: widget.style.copyWith(
                color: color,
                decoration: TextDecoration.none,
              ),
              maxLines: widget.maxLines,
              overflow: widget.overflow,
              textAlign: widget.textAlign,
            ),
            if (t > 0.001)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _StrikePainter(
                      text: widget.text,
                      style: widget.style.copyWith(
                        color: color,
                        decoration: TextDecoration.none,
                      ),
                      progress: t,
                      maxLines: widget.maxLines,
                      textAlign: widget.textAlign,
                      textDirection: Directionality.of(context),
                      textScaler: MediaQuery.textScalerOf(context),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Dibuja la línea de tachado sobre cada línea del texto según el progreso.
class _StrikePainter extends CustomPainter {
  _StrikePainter({
    required this.text,
    required this.style,
    required this.progress,
    required this.maxLines,
    required this.textAlign,
    required this.textDirection,
    required this.textScaler,
  });

  final String text;
  final TextStyle style;
  final double progress;
  final int? maxLines;
  final TextAlign? textAlign;
  final TextDirection textDirection;
  final TextScaler textScaler;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: textDirection,
      textAlign: textAlign ?? TextAlign.start,
      maxLines: maxLines,
      textScaler: textScaler,
    )..layout(maxWidth: size.width);

    final paint = Paint()
      ..color = style.color ?? const Color(0xFF000000)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    for (final line in painter.computeLineMetrics()) {
      final lineCenterY = line.baseline - line.ascent + line.height / 2;
      final left = line.left;
      final width = line.width * progress;
      canvas.drawLine(
        Offset(left, lineCenterY),
        Offset(left + width, lineCenterY),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StrikePainter oldDelegate) =>
      oldDelegate.text != text ||
      oldDelegate.style != style ||
      oldDelegate.progress != progress ||
      oldDelegate.maxLines != maxLines ||
      oldDelegate.textAlign != textAlign ||
      oldDelegate.textDirection != textDirection;
}
