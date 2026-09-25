import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';

/// Aviso breve en la parte superior, justo bajo la barra del shell.
///
/// Sustituye a los `SnackBar`: al ser flotantes caían sobre la BottomBar y el
/// FAB, pegados al borde inferior, y tapaban también el campo de añadido
/// rápido de las tareas. Un overlay propio en la parte de arriba deja libre
/// toda esa zona.
class AppToast {
  AppToast._();

  /// Alto de la barra superior del shell por debajo del área segura: el
  /// IconButton (48) más su padding inferior (8), ver `app_shell.dart`.
  static const double _shellTopBarHeight = 56;

  static OverlayEntry? _entry;

  /// Muestra [message] arriba. Un aviso nuevo reemplaza al anterior.
  static void show(BuildContext context, String message) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    _removeCurrent();

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ToastCard(
        message: message,
        onDismissed: () {
          if (!identical(_entry, entry)) return;
          _entry = null;
          if (entry.mounted) entry.remove();
        },
      ),
    );
    _entry = entry;
    overlay.insert(entry);
  }

  static void _removeCurrent() {
    final current = _entry;
    _entry = null;
    if (current != null && current.mounted) current.remove();
  }
}

/// Card del aviso: entra deslizándose desde arriba, se queda unos segundos y
/// se va sola. Tocarla la descarta antes de tiempo.
class _ToastCard extends StatefulWidget {
  const _ToastCard({required this.message, required this.onDismissed});

  final String message;
  final VoidCallback onDismissed;

  @override
  State<_ToastCard> createState() => _ToastCardState();
}

class _ToastCardState extends State<_ToastCard>
    with SingleTickerProviderStateMixin {
  static const Duration _visibleFor = Duration(seconds: 3);
  static const Duration _slide = Duration(milliseconds: 200);

  late final AnimationController _controller;
  late final CurvedAnimation _curved;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _slide);
    _curved = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.forward();
    _hideTimer = Timer(_visibleFor, _hide);
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _curved.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _hide() {
    if (!mounted) return;
    _controller.reverse().then((_) {
      if (mounted) widget.onDismissed();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final top =
        MediaQuery.paddingOf(context).top +
        AppToast._shellTopBarHeight +
        AppSpacing.sm;

    return Positioned(
      top: top,
      left: AppSpacing.lg,
      right: AppSpacing.lg,
      child: FadeTransition(
        opacity: _curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.6),
            end: Offset.zero,
          ).animate(_curved),
          child: Align(
            alignment: Alignment.topCenter,
            child: GestureDetector(
              onTap: _hide,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surfaceDark,
                  borderRadius: AppRadius.brPill,
                  boxShadow: [
                    BoxShadow(
                      color: colors.shadowDark,
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.md,
                  ),
                  child: Text(
                    widget.message,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySm.copyWith(color: colors.onDark),
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
