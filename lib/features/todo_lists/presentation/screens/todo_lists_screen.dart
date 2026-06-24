import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../routing/routes.dart';
import '../../../../shared/core/theme/app_spacing.dart';
import '../../../../shared/core/theme/app_theme.dart';
import '../../../../shared/core/theme/app_typography.dart';
import '../../domain/entities/todo_list.dart';
import '../providers/todo_lists_provider.dart';
import '../providers/todo_lists_state.dart';
import '../widgets/empty_state.dart';
import '../widgets/todo_list_tile.dart';

/// Pantalla raíz tras login. Muestra todas las listas de TODOs del usuario.
/// El Scaffold, AppBar, FAB y BottomBar viven en [AppShell].
class TodoListsScreen extends ConsumerWidget {
  const TodoListsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(todoListsProvider);
    return _buildBody(context, state);
  }

  Widget _buildBody(BuildContext context, TodoListsState state) {
    // Offset para no tapar el contenido bajo el AppBar anclado.
    // statusBar + iconButton (48) + padding bottom del AppBar + gap.
    final topOffset = MediaQuery.of(context).padding.top + 56 + AppSpacing.md;

    return switch (state) {
      TodoListsInitial() ||
      TodoListsLoading() =>
        const Center(child: CircularProgressIndicator()),
      TodoListsError(:final failure) => Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.xxxl).copyWith(top: topOffset),
            child: Text(
              failure.message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMd.copyWith(color: context.colors.body),
            ),
          ),
        ),
      TodoListsData(:final items) => items.isEmpty
          ? Padding(
              padding: EdgeInsets.only(top: topOffset),
              child: const TodoListsEmptyState(),
            )
          : _Lists(items: items, topPadding: topOffset),
    };
  }
}

class _Lists extends ConsumerWidget {
  const _Lists({required this.items, required this.topPadding});

  final List<TodoList> items;
  final double topPadding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(todoListsProvider.notifier);

    // Más recientes primero (criterio que la UX puede revisar luego).
    final sorted = [...items]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        topPadding,
        AppSpacing.lg,
        AppSpacing.section,
      ),
      itemCount: sorted.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, i) {
        final list = sorted[i];
        return TodoListTile(
          list: list,
          onTap: () => context.push(Routes.todoList(list.id)),
          onEdit: () => context.push(Routes.todoListEdit(list.id)),
          onDelete: () async {
            await notifier.delete(list.id);
            if (!context.mounted) return;
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(content: Text('Lista «${list.name}» eliminada.')),
              );
          },
        );
      },
    );
  }
}
