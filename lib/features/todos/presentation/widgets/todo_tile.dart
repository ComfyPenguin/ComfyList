import 'package:flutter/material.dart';

import '../../../../shared/core/theme/app_radius.dart';
import '../../../../shared/core/theme/app_spacing.dart';
import '../../../../shared/core/theme/app_theme.dart';
import '../../../../shared/core/theme/app_typography.dart';
import '../../../../shared/ui/lists/swipe_reveal_actions.dart';
import '../../../../shared/ui/recycle_bin_icon.dart';
import '../../domain/entities/todo.dart';

/// Item de la lista de tareas — `card-content` plana (canvas-soft + radio xl).
/// Swipe a la derecha revela el botón de editar; swipe a la izquierda revela
/// el botón de borrar. El borrado es sin confirmación.
class TodoTile extends StatefulWidget {
  const TodoTile({
    super.key,
    required this.todo,
    required this.onToggle,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final Todo todo;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<TodoTile> createState() => _TodoTileState();
}

class _TodoTileState extends State<TodoTile> {
  double _lastRightReveal = 0;
  int _rightRevealCount = 0;

  void _onRightReveal(double progress) {
    // Dispara al cruzar el umbral de apertura (~-0.6, igual que el
    // openThreshold interno del swipe). Detecta la transición incluso
    // si el drag empieza desde un valor intermedio (p. ej. drag rápido
    // que salta de 0 a -1 en pocos frames).
    if (_lastRightReveal > -0.6 && progress <= -0.6) {
      setState(() => _rightRevealCount++);
    }
    _lastRightReveal = progress;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final muted = colors.muted;
    final titleStyle = AppTypography.bodyMdStrong.copyWith(
      decoration: widget.todo.isDone ? TextDecoration.lineThrough : null,
      color: widget.todo.isDone ? muted : colors.ink,
    );

    return Material(
      color: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.brXl),
      clipBehavior: Clip.antiAlias,
      child: SwipeRevealActions(
        onRightRevealProgressChanged: _onRightReveal,
        leftAction: SwipeRevealAction(
          icon: const Icon(Icons.edit_outlined),
          label: 'Editar tarea',
          background: colors.surfacePressed,
          foreground: colors.ink,
          onTap: widget.onEdit,
        ),
        rightAction: SwipeRevealAction(
          icon: RecycleBinIcon(key: ValueKey(_rightRevealCount)),
          label: 'Eliminar tarea',
          background: colors.error,
          foreground: colors.onError,
          onTap: widget.onDelete,
        ),
        child: Material(
          color: colors.canvasSoft,
          child: InkWell(
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.lg,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => widget.onToggle(!widget.todo.isDone),
                    child: Checkbox(
                      value: widget.todo.isDone,
                      onChanged: (v) => widget.onToggle(v ?? false),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(widget.todo.title, style: titleStyle),
                        if (widget.todo.description != null &&
                            widget.todo.description!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.xs),
                            child: Text(
                              widget.todo.description!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodySm.copyWith(
                                color: muted,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Icon(Icons.chevron_right, color: colors.muted),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
