import 'package:flutter/material.dart';

import '../../../../shared/core/theme/app_spacing.dart';
import '../../../../shared/core/theme/app_theme.dart';
import '../../../../shared/core/theme/app_typography.dart';
import '../../../../shared/ui/lists/swipe_reveal_card.dart';
import '../../domain/entities/todo_list.dart';
import '../../domain/entities/todo_list_icons.dart';

/// Item de la pantalla de listas con acciones de editar y borrar mediante swipe.
class TodoListTile extends StatelessWidget {
  const TodoListTile({
    super.key,
    required this.list,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    this.groupIndex = 0,
    this.groupSize = 1,
    this.topSeparationProgress = 1,
    this.bottomSeparationProgress = 1,
    this.onRevealProgressChanged,
  });

  final TodoList list;
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

    return SwipeRevealCard(
      onTap: onTap,
      onEdit: onEdit,
      onDelete: onDelete,
      editLabel: 'Editar lista',
      deleteLabel: 'Eliminar lista',
      groupIndex: groupIndex,
      groupSize: groupSize,
      topSeparationProgress: topSeparationProgress,
      bottomSeparationProgress: bottomSeparationProgress,
      onRevealProgressChanged: onRevealProgressChanged,
      child: Row(
        children: [
          Icon(
            TodoListIcons.resolve(list.iconKey),
            color: colors.ink,
            size: 28,
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Text(
              list.name,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodyMdStrong.copyWith(color: colors.ink),
            ),
          ),
          Icon(Icons.chevron_right, color: colors.muted),
        ],
      ),
    );
  }
}
