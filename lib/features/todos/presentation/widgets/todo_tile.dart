import 'package:flutter/material.dart';

import '../../../../shared/core/theme/app_spacing.dart';
import '../../../../shared/core/theme/app_theme.dart';
import '../../../../shared/core/theme/app_typography.dart';
import '../../../../shared/ui/lists/swipe_reveal_card.dart';
import '../../domain/entities/todo.dart';

/// Item de la lista de tareas con acciones de editar y borrar mediante swipe.
class TodoTile extends StatelessWidget {
  const TodoTile({
    super.key,
    required this.todo,
    required this.onToggle,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    this.groupIndex = 0,
    this.groupSize = 1,
    this.topSeparationProgress = 1,
    this.bottomSeparationProgress = 1,
    this.onRevealProgressChanged,
  });

  final Todo todo;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final int groupIndex;
  final int groupSize;
  final double topSeparationProgress;
  final double bottomSeparationProgress;
  final ValueChanged<double>? onRevealProgressChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final muted = colors.muted;
    final titleStyle = AppTypography.bodyMdStrong.copyWith(
      decoration: todo.isDone ? TextDecoration.lineThrough : null,
      color: todo.isDone ? muted : colors.ink,
    );

    return SwipeRevealCard(
      onTap: onTap,
      onEdit: onEdit,
      onDelete: onDelete,
      editLabel: 'Editar tarea',
      deleteLabel: 'Eliminar tarea',
      groupIndex: groupIndex,
      groupSize: groupSize,
      topSeparationProgress: topSeparationProgress,
      bottomSeparationProgress: bottomSeparationProgress,
      onRevealProgressChanged: onRevealProgressChanged,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onToggle(!todo.isDone),
            child: Checkbox(
              value: todo.isDone,
              onChanged: (value) => onToggle(value ?? false),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(todo.title, style: titleStyle),
                if (todo.description != null && todo.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(
                      todo.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySm.copyWith(color: muted),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Icon(Icons.chevron_right, color: colors.muted),
        ],
      ),
    );
  }
}
