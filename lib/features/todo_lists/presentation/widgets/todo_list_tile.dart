import 'package:flutter/material.dart';

import '../../../../shared/core/theme/app_radius.dart';
import '../../../../shared/core/theme/app_spacing.dart';
import '../../../../shared/core/theme/app_theme.dart';
import '../../../../shared/core/theme/app_typography.dart';
import '../../../../shared/ui/lists/swipe_reveal_actions.dart';
import '../../../../shared/ui/recycle_bin_icon.dart';
import '../../domain/entities/todo_list.dart';
import '../../domain/entities/todo_list_icons.dart';

/// Item de la pantalla de listas — card plana con icono + nombre, mismo
/// patrón visual que [TodoTile] (canvas-soft + radio xl).
/// Swipe a la izquierda revela un botón de borrar (elimina la lista y
/// sus tareas en cascada, sin confirmación). Swipe a la derecha revela
/// un botón de editar que abre la pantalla de edición.
class TodoListTile extends StatefulWidget {
  const TodoListTile({
    super.key,
    required this.list,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final TodoList list;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<TodoListTile> createState() => _TodoListTileState();
}

class _TodoListTileState extends State<TodoListTile> {
  double _lastRightReveal = 0;
  int _rightRevealCount = 0;

  void _onRightReveal(double progress) {
    if (_lastRightReveal > -0.6 && progress <= -0.6) {
      setState(() => _rightRevealCount++);
    }
    _lastRightReveal = progress;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.brXl),
      clipBehavior: Clip.antiAlias,
      child: SwipeRevealActions(
        onRightRevealProgressChanged: _onRightReveal,
        leftAction: SwipeRevealAction(
          icon: const Icon(Icons.edit_outlined),
          label: 'Editar lista',
          background: colors.surfacePressed,
          foreground: colors.ink,
          onTap: widget.onEdit,
        ),
        rightAction: SwipeRevealAction(
          icon: RecycleBinIcon(key: ValueKey(_rightRevealCount)),
          label: 'Eliminar lista',
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
                children: [
                  Icon(
                    TodoListIcons.resolve(widget.list.iconKey),
                    color: colors.ink,
                    size: 28,
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Text(
                      widget.list.name,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMdStrong.copyWith(
                        color: colors.ink,
                      ),
                    ),
                  ),
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
