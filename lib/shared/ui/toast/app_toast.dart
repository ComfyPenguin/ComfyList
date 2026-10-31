import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadow.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';

/// Aviso breve en la parte superior, por encima de la barra del shell.
///
/// Sustituye a los `SnackBar`: al ser flotantes caían sobre la BottomBar y el
/// FAB, pegados al borde inferior, y tapaban también el campo de añadido
/// rápido de las tareas. Un overlay propio en la parte de arriba deja libre
/// toda esa zona, y encima de la barra no tapa la primera fila de la lista.
class AppToast {
  AppToast._();

  /// Textos de los avisos. Cada mensaje vive aquí una sola vez, aunque lo
  /// muestren varias pantallas.
  static const String listDeleted = 'Lista eliminada.';
  static const String todoDeleted = 'Tarea eliminada.';
  static const String appointmentDeleted = 'Cita eliminada.';
  static const String undo = 'Deshacer';
  static const String undoFailed = 'No se pudo deshacer. Inténtalo de nuevo.';
  static const String restoreFailed =
      'No se ha podido restaurar. Inténtalo de nuevo.';
  static const String listDeleteFailed =
      'No se ha podido eliminar la lista. Inténtalo de nuevo.';
  static const String todoDeleteFailed =
      'No se ha podido eliminar la tarea. Inténtalo de nuevo.';
  static const String appointmentDeleteFailed =
      'No se ha podido eliminar la cita. Inténtalo de nuevo.';
  static const String saveFailed =
      'No se ha podido guardar. Inténtalo de nuevo.';
  static const String updateFailed =
      'No se ha podido actualizar. Inténtalo de nuevo.';
  static const String trashEmptied = 'Papelera vaciada.';
  static const String longPressHint =
      'Mantén pulsada una tarjeta para editarla.';
  static const String notificationsStillBlocked =
      'Sigue bloqueado: actívalos en los ajustes del sistema.';

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

    _show(overlay, message, actionLabel: actionLabel, onAction: onAction);
  }

  /// Aviso de un borrado, con «Deshacer». [onUndo] devuelve si el elemento
  /// volvió; si no, se avisa del fallo.
  static void showUndo(
    BuildContext context, {
    required String message,
    required Future<bool> Function() onUndo,
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    _show(
      overlay,
      message,
      actionLabel: undo,
      onAction: () async {
        if (await onUndo()) return;
        _show(overlay, undoFailed);
      },
    );
  }

  /// El overlay se resuelve una sola vez: el aviso sigue en pie y con su
  /// mensaje aunque la pantalla desde la que se borró ya no exista.
  static void _show(
    OverlayState overlay,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
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

  static void _removeCurrent() {
    final current = _entry;
    _entry = null;
    if (current != null && current.mounted) current.remove();
  }
}

/// Card del aviso: entra deslizándose desde arriba, se queda unos segundos y
/// se va sola. Con acción se puede tocar en cualquier punto de la tarjeta para
/// ejecutarla; sin acción, tocarla la descarta antes de tiempo. Tocar en
/// cualquier otro sitio también la descarta, y ese toque sigue su camino.
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
  static const Duration _visibleForAction = Duration(seconds: 8);
  static const Duration _slide = Duration(milliseconds: 200);

  late final AnimationController _controller;
  late final CurvedAnimation _curved;
  Timer? _hideTimer;
  bool _hiding = false;

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
    if (!mounted || _hiding) return;
    _hiding = true;
    _hideTimer?.cancel();
    _controller.reverse().then((_) {
      if (mounted) widget.onDismissed();
    });
  }

  void _runAction() {
    widget.onAction?.call();
    _hide();
  }

  /// Con acción el aviso entero la ejecuta: el botón es pequeño y un toque al
  /// lado no debe llevarse por delante la única oportunidad de deshacer. Sin
  /// acción, tocar el aviso lo descarta.
  void _handleCardTap() {
    if (widget.actionLabel != null) {
      _runAction();
    } else {
      _hide();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final actionLabel = widget.actionLabel;
    final top = MediaQuery.paddingOf(context).top + AppSpacing.sm;

    return Positioned.fill(
      child: Stack(
        children: [
          // Translúcido: avisa del toque pero lo deja pasar a lo de debajo.
          Positioned.fill(
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (_) => _hide(),
            ),
          ),
          Positioned(
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
                    onTap: _handleCardTap,
                    // Que el hueco entre el mensaje y el botón también cuente: sin
                    // esto, el toque en el relleno del aviso no llega a nada.
                    behavior: HitTestBehavior.opaque,
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
                                  color: colors.onPrimary.withValues(
                                    alpha: 0.24,
                                  ),
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
          ),
        ],
      ),
    );
  }
}

/// Acción del aviso: el icono de deshacer y el texto en negrita, sin relleno.
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.undo_rounded, size: 16, color: colors.onPrimary),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  label,
                  style: AppTypography.bodySmStrong.copyWith(
                    color: colors.onPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
