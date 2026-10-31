import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../routing/routes.dart';
import '../../../../shared/core/theme/app_spacing.dart';
import '../../../../shared/core/theme/app_theme.dart';
import '../../../../shared/core/theme/app_typography.dart';
import '../../../../shared/ui/lists/reveal_progress.dart';
import '../../../../shared/ui/toast/app_toast.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../settings/presentation/providers/settings_state.dart';
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
      TodoListsLoading() => const Center(child: CircularProgressIndicator()),
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
      TodoListsData(:final items) =>
        items.isEmpty
            ? Padding(
                padding: EdgeInsets.only(top: topOffset),
                child: const TodoListsEmptyState(),
              )
            : _Lists(items: items, topPadding: topOffset),
    };
  }
}

class _Lists extends ConsumerStatefulWidget {
  const _Lists({required this.items, required this.topPadding});

  final List<TodoList> items;
  final double topPadding;

  @override
  ConsumerState<_Lists> createState() => _ListsState();
}

class _ListsState extends ConsumerState<_Lists> {
  static const double _joinedGap = 2;

  final _reveal = RevealProgress();

  /// Evita programar la pista más de una vez mientras el aviso se muestra.
  bool _hintScheduled = false;

  void _setTileRevealProgress(String listId, double progress) {
    setState(() => _reveal.set(listId, progress));
  }

  /// Muestra una única vez la pista del gesto: mantener pulsada una tarjeta
  /// la abre en edición. Solo con ajustes cargados y sin haberla visto antes.
  void _maybeShowLongPressHint() {
    if (_hintScheduled) return;
    final settings = switch (ref.watch(settingsProvider)) {
      SettingsData(:final settings) => settings,
      _ => null,
    };
    if (settings == null || settings.longPressHintSeen) return;

    _hintScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AppToast.show(context, AppToast.longPressHint);
      ref.read(settingsProvider.notifier).setLongPressHintSeen(true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(todoListsProvider.notifier);
    _maybeShowLongPressHint();
    final sorted = [...widget.items]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    _reveal.retainOnly([for (final list in sorted) list.id]);

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
        final list = sorted[i];
        final separation = _reveal.separationFor(
          list.id,
          previousId: i > 0 ? sorted[i - 1].id : null,
          nextId: i < sorted.length - 1 ? sorted[i + 1].id : null,
        );
        return TodoListTile(
          key: ValueKey(list.id),
          list: list,
          groupIndex: i,
          groupSize: sorted.length,
          topSeparationProgress: separation.top,
          bottomSeparationProgress: separation.bottom,
          onRevealProgressChanged: (progress) =>
              _setTileRevealProgress(list.id, progress),
          onTap: () => context.push(Routes.todoList(list.id)),
          onLongPress: () => context.push(Routes.todoListEdit(list.id)),
          onDelete: () async {
            final deleted = await notifier.delete(list.id);
            if (!context.mounted) return;

            if (deleted == null) {
              AppToast.show(context, AppToast.listDeleteFailed);
              return;
            }
            AppToast.showUndo(
              context,
              message: AppToast.listDeleted,
              onUndo: () => notifier.undo(deleted),
            );
          },
        );
      },
    );
  }
}
