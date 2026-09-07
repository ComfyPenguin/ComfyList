import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../routing/routes.dart';
import '../../../../shared/core/theme/app_radius.dart';
import '../../../../shared/core/theme/app_spacing.dart';
import '../../../../shared/core/theme/app_theme.dart';
import '../../../../shared/core/theme/app_typography.dart';
import '../../../../shared/ui/navigation/app_shell.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../settings/presentation/providers/settings_state.dart';
import '../../domain/entities/todo.dart';
import '../providers/todos_provider.dart';
import '../providers/todos_state.dart';
import '../widgets/empty_state.dart';
import '../widgets/quick_add_bar.dart';
import '../widgets/todo_detail_sheet.dart';
import '../widgets/todo_tile.dart';

/// Pantalla de tareas de una lista. El Scaffold, AppBar, FAB y BottomBar
/// viven en [AppShell].
class TodosScreen extends ConsumerWidget {
  const TodosScreen({super.key, required this.listId});

  final String listId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(todosProvider(listId));
    return _buildBody(context, ref, state);
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, TodosState state) {
    return switch (state) {
      TodosInitial() ||
      TodosLoading() => const Center(child: CircularProgressIndicator()),
      TodosError(:final failure) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxxl),
          child: Text(
            failure.message,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMd.copyWith(color: context.colors.body),
          ),
        ),
      ),
      TodosData(:final items) => _buildTodosData(context, ref, items),
    };
  }

  Widget _buildTodosData(
    BuildContext context,
    WidgetRef ref,
    List<Todo> items,
  ) {
    final colors = context.colors;
    final isDark = colors.canvas.computeLuminance() < 0.05;
    // Altura acumulada: safe area + margen appbar + appbar + gap
    final topOffset =
        MediaQuery.of(context).padding.top +
        AppSpacing
            .sm // margen del AppBar
            +
        52 // altura del AppBar
        +
        AppSpacing.sm; // gap entre AppBar y QuickAddBar

    final contentTopPadding = topOffset + 52 + AppSpacing.sm;

    return Stack(
      children: [
        // ── Contenido scrolleable, ocupa toda la pantalla desde y=0 ──
        Positioned.fill(
          child: items.isEmpty
              ? Padding(
                  padding: EdgeInsets.only(top: contentTopPadding),
                  child: const TodosEmptyState(),
                )
              : _TodosList(
                  listId: listId,
                  items: items,
                  topPadding: contentTopPadding,
                ),
        ),
        // ── QuickAddBar glassmorphism flotante ──
        Positioned(
          left: 0,
          right: 0,
          top: topOffset,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: ClipRRect(
              borderRadius: AppRadius.brPill,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  height: 52,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  decoration: BoxDecoration(
                    color: colors.canvas.withValues(alpha: 0.7),
                    borderRadius: AppRadius.brPill,
                    border: Border.all(
                      color: isDark
                          ? colors.ink.withValues(alpha: 0.18)
                          : colors.ink.withValues(alpha: 0.12),
                      width: 1.2,
                    ),
                  ),
                  child: QuickAddBar(
                    hint: 'Añadir tarea rápida...',
                    autofocus: items.isEmpty,
                    onSubmit: (title) => ref
                        .read(todosProvider(listId).notifier)
                        .create(title: title),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TodosList extends ConsumerStatefulWidget {
  const _TodosList({
    required this.listId,
    required this.items,
    required this.topPadding,
  });

  final String listId;
  final List<Todo> items;
  final double topPadding;

  @override
  ConsumerState<_TodosList> createState() => _TodosListState();
}

class _TodosListState extends ConsumerState<_TodosList> {
  static const double _joinedGap = 2;

  final _tileRevealProgress = <String, double>{};

  ({double top, double bottom}) _effectiveSeparationFor(
    int tileIndex,
    List<Todo> todos,
  ) {
    if (_tileRevealProgress.isEmpty) {
      return (top: 0.0, bottom: 0.0);
    }

    final currentId = todos[tileIndex].id;
    final currentProgress = _tileRevealProgress[currentId] ?? 0.0;
    final previousProgress = tileIndex > 0
        ? (_tileRevealProgress[todos[tileIndex - 1].id] ?? 0.0)
        : 0.0;
    final nextProgress = tileIndex < todos.length - 1
        ? (_tileRevealProgress[todos[tileIndex + 1].id] ?? 0.0)
        : 0.0;

    return (
      top: currentProgress > previousProgress
          ? currentProgress
          : previousProgress,
      bottom: currentProgress > nextProgress ? currentProgress : nextProgress,
    );
  }

  void _setTileRevealProgress(String todoId, double progress) {
    final value = progress.clamp(0.0, 1.0).toDouble();
    if (value <= 0.001) {
      _tileRevealProgress.remove(todoId);
    } else {
      _tileRevealProgress[todoId] = value;
    }
    setState(() {});
  }

  void _removeStaleRevealProgress(List<Todo> todos) {
    final visibleIds = todos.map((todo) => todo.id).toSet();
    _tileRevealProgress.removeWhere((id, _) => !visibleIds.contains(id));
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(todosProvider(widget.listId).notifier);
    final completedToBottom = switch (ref.watch(settingsProvider)) {
      SettingsData(:final settings) => settings.completedToBottom,
      _ => true,
    };

    // Ordenar según el ajuste:
    // - Activado: pendientes primero, luego por fecha de actualización desc.
    // - Desactivado: por fecha de creación asc (mantiene la posición siempre).
    final sorted = [...widget.items]
      ..sort((a, b) {
        if (completedToBottom) {
          if (a.isDone != b.isDone) return a.isDone ? 1 : -1;
          return b.updatedAt.compareTo(a.updatedAt);
        }
        return a.createdAt.compareTo(b.createdAt);
      });
    _removeStaleRevealProgress(sorted);

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        widget.topPadding,
        AppSpacing.lg,
        AppSpacing.section,
      ),
      itemCount: sorted.length,
      separatorBuilder: (_, _) => const SizedBox(height: _joinedGap),
      itemBuilder: (context, i) {
        final todo = sorted[i];
        final separation = _effectiveSeparationFor(i, sorted);
        return TodoTile(
          key: ValueKey(todo.id),
          todo: todo,
          groupIndex: i,
          groupSize: sorted.length,
          topSeparationProgress: separation.top,
          bottomSeparationProgress: separation.bottom,
          onRevealProgressChanged: (progress) =>
              _setTileRevealProgress(todo.id, progress),
          onToggle: (v) => notifier.toggleDone(todo.id, v),
          onTap: () => _showDetailSheet(context, ref, todo.id),
          onEdit: () => context.push(Routes.todoEdit(widget.listId, todo.id)),
          onDelete: () async {
            await notifier.delete(todo.id);
            if (!context.mounted) return;
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(content: Text('Tarea «${todo.title}» eliminada.')),
              );
          },
        );
      },
    );
  }

  void _showDetailSheet(BuildContext context, WidgetRef ref, String todoId) {
    ref.read(detailSheetOpenProvider.notifier).open();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => TodoDetailSheet(
        listId: widget.listId,
        todoId: todoId,
        onEdit: () {
          Navigator.of(sheetContext).pop();
          Future.microtask(() {
            if (!context.mounted) return;
            context.push(Routes.todoEdit(widget.listId, todoId));
          });
        },
      ),
    ).whenComplete(() {
      ref.read(detailSheetOpenProvider.notifier).close();
    });
  }
}
