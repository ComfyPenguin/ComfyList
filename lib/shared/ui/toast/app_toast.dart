import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadow.dart';
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

  /// Textos de los avisos. Cada mensaje vive aquí una sola vez, aunque lo
  /// muestren varias pantallas.
  static const String listDeleted = 'Lista eliminada.';
  static const String todoDeleted = 'Tarea eliminada.';
  static const String appointmentDeleted = 'Cita eliminada.';
  static const String undo = 'Deshacer';
  static const String undoFailed = 'No se pudo deshacer. Inténtalo de nuevo.';
  static const String longPressHint =
      'Mantén pulsada una tarjeta para editarla.';
  static const String notificationsStillBlocked =
      'Sigue bloqueado: actívalos en los ajustes del sistema.';

  /// Alto de la barra superior del shell por debajo del área segura: el
  /// IconButton (48) más su padding inferior (8), ver `app_shell.dart`.
  static const double _shellTopBarHeight = 56;

  static OverlayEntry? _entry;

  /// Muestra [message] arriba. Un aviso nuevo reemplaza al anterior.
  static void show(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    _removeCurrent();

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ToastCard(
        message: message,
        actionLabel: actionLabel,
        onAction: onAction,
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

  /// Aviso de un borrado, con «Deshacer». [onUndo] devuelve si el elemento
  /// volvió; si no, se avisa del fallo.
  static void showUndo(
    BuildContext context, {
    required String message,
    required Future<bool> Function() onUndo,
  }) {
    show(
      context,
      message,
      actionLabel: undo,
      onAction: () async {
        if (await onUndo()) return;
        if (!context.mounted) return;
        show(context, undoFailed);
      },
    );
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
  const _ToastCard({
    required this.message,
    required this.onDismissed,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onDismissed;

  @override
  State<_ToastCard> createState() => _ToastCardState();
}

class _ToastCardState extends State<_ToastCard>
    with SingleTickerProviderStateMixin {
  /// Con acción el aviso necesita más tiempo: hay que leerlo y decidir.
  static const Duration _visibleFor = Duration(seconds: 2);
  static const Duration _visibleForAction = Duration(seconds: 5);
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
    _hideTimer = Timer(
      widget.actionLabel == null ? _visibleFor : _visibleForAction,
      _hide,
    );
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

  void _runAction() {
    widget.onAction?.call();
    _hide();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final actionLabel = widget.actionLabel;
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
              // El overlay raíz cuelga por encima del Navigator: sin un Material
              // por medio, el texto hereda el estilo de error de Flutter y sale
              // subrayado en amarillo.
              child: Material(
                type: MaterialType.transparency,
                child: DecoratedBox(
                  // Primario de la app: oscuro en claro y claro en oscuro, el
                  // contraste inverso al canvas. Con su halo de elemento primario.
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: AppRadius.brPill,
                    boxShadow: AppShadow.primaryGlow(colors),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            widget.message,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySm.copyWith(
                              color: colors.onPrimary,
                            ),
                          ),
                        ),
                        if (actionLabel != null) ...[
                          const SizedBox(width: AppSpacing.md),
                          // Línea al alto de la línea de texto: separa los dos
                          // bloques sin partir el aviso en dos.
                          Container(
                            width: 1,
                            height: AppSpacing.xl,
                            color: colors.onPrimary.withValues(alpha: 0.24),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          _ToastAction(
                            label: actionLabel,
                            onTap: _runAction,
                          ),
                        ],
                      ],
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

/// Acción del aviso: texto en negrita, sin relleno, con su respuesta al tacto.
///
/// Sobre el `Material` transparente el ripple sí se ve: se pinta por encima del
/// fondo del aviso, que es un `DecoratedBox` de un ancestro.
class _ToastAction extends StatelessWidget {
  const _ToastAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.brPill,
          // El brillo del tema apenas se distingue sobre el primario, así que
          // el del pulsar sale del color que contrasta.
          splashColor: colors.onPrimary.withValues(alpha: 0.18),
          highlightColor: colors.onPrimary.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            child: Text(
              label,
              style: AppTypography.bodySmStrong.copyWith(
                color: colors.onPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
