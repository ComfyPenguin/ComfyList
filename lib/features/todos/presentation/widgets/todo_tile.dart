import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/core/theme/app_spacing.dart';
import '../../../../shared/core/theme/app_theme.dart';
import '../../../../shared/core/theme/app_typography.dart';
import '../../../../shared/ui/lists/swipe_actions_card.dart';
import '../../../../shared/ui/text/animated_strikethrough_text.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../settings/presentation/providers/settings_state.dart';
import '../../domain/entities/todo.dart';

/// Item de la lista de tareas con acciones de completar y borrar mediante swipe.
class TodoTile extends ConsumerWidget {
  const TodoTile({
    super.key,
    required this.todo,
    required this.onTap,
    required this.onComplete,
    required this.onDelete,
    this.onLongPress,
    this.groupIndex = 0,
    this.groupSize = 1,
    this.topSeparationProgress = 1,
    this.bottomSeparationProgress = 1,
    this.onRevealProgressChanged,
  });

  final Todo todo;
  final VoidCallback onTap;
  final VoidCallback onComplete;
  final VoidCallback onDelete;
  final VoidCallback? onLongPress;
  final int groupIndex;
  final int groupSize;
  final double topSeparationProgress;
  final double bottomSeparationProgress;
  final ValueChanged<double>? onRevealProgressChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final muted = colors.muted;
    final titleStyle = AppTypography.bodyMdStrong;
    final invertActions = switch (ref.watch(settingsProvider)) {
      SettingsData(:final settings) => settings.invertSwipeActions,
      _ => false,
    };

    return SwipeActionsCard(
      onTap: onTap,
      onLongPress: onLongPress,
      onDelete: onDelete,
      onComplete: onComplete,
      isDone: todo.isDone,
      invertActions: invertActions,
      groupIndex: groupIndex,
      groupSize: groupSize,
      topSeparationProgress: topSeparationProgress,
      bottomSeparationProgress: bottomSeparationProgress,
      onRevealProgressChanged: onRevealProgressChanged,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedStrikethroughText(
                  text: todo.title,
                  style: titleStyle.copyWith(color: colors.ink),
                  done: todo.isDone,
                  doneColor: muted,
                ),
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
        ],
      ),
    );
  }
}
