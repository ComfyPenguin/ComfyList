import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../routing/routes.dart';
import '../../../../shared/core/theme/app_spacing.dart';
import '../../../../shared/core/theme/app_theme.dart';
import '../../../../shared/core/theme/app_typography.dart';
import '../../../../shared/ui/lists/held_reorder.dart';
import '../../../../shared/ui/lists/reveal_progress.dart';
import '../../../../shared/ui/lists/slide_flow.dart';
import '../../../../shared/ui/navigation/app_shell.dart';
import '../../../../shared/ui/toast/app_toast.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../domain/entities/todo.dart';
import '../../domain/todo_order.dart';
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
    // El shell superpone el AppBar y el dock sobre el body; reservamos
    // espacio para que el contenido no quede oculto bajo ninguno de los dos.
    final topOffset =
        MediaQuery.of(context).padding.top +
        AppSpacing
            .sm // margen del AppBar
            +
        52 // altura del AppBar
        +
        AppSpacing.sm; // separación hasta el contenido
    final bottomDockHeight =
        72 + AppSpacing.lg + MediaQuery.viewPaddingOf(context).bottom;
    final keyboardInset =
        KeyboardVisibilityScope.bottomInsetOf(context) >
            MediaQuery.viewInsetsOf(context).bottom
        ? KeyboardVisibilityScope.bottomInsetOf(context)
        : MediaQuery.viewInsetsOf(context).bottom;
    final keyboardVisible = keyboardInset > 0;
    final quickAddHeight = 52.0;
    final quickAddGap = AppSpacing.sm;
    const keyboardQuickAddGap = 6.0;
    // El Scaffold reduce la altura del body cuando aparece el teclado. Por
    // eso, en ese estado basta con separar el QuickAddBar del nuevo borde
    // inferior; no sumamos el inset del teclado una segunda vez.
    //
    // Al ocultarse el teclado, su inset baja gradualmente hasta cero mientras
    // el BottomBar ya está colocado en su posición final. No permitimos que
    // el QuickAddBar baje por debajo de ese dock: así la animación termina
    // sobre la BottomBar en lugar de tocar el borde inferior y ser recolocada
    // después.
    final quickAddBaseOffset = keyboardInset > bottomDockHeight
        ? keyboardInset
        : bottomDockHeight;
    final quickAddBottom =
        quickAddBaseOffset +
        (keyboardVisible ? keyboardQuickAddGap : quickAddGap);
    final contentBottomPadding =
        quickAddBaseOffset +
        quickAddHeight +
        (keyboardVisible ? keyboardQuickAddGap : quickAddGap);

    return Stack(
      children: [
        // ── Contenido scrolleable, ocupa toda la pantalla desde y=0 ──
        Positioned.fill(
          child: items.isEmpty
              ? Padding(
                  padding: EdgeInsets.only(
                    top: topOffset,
                    bottom: contentBottomPadding,
                  ),
                  child: const TodosEmptyState(),
                )
              : _TodosList(
                  listId: listId,
                  items: items,
                  topPadding: topOffset,
                  bottomPadding: contentBottomPadding,
                ),
        ),
        // ── QuickAddBar flotante sobre el dock ──
        Positioned(
          left: 0,
          right: 0,
          bottom: quickAddBottom,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: QuickAddBar(
              hint: 'Añadir tarea rápida...',
              showSubmitButton: keyboardVisible,
              onSubmit: (title) async {
                final saved = await ref
                    .read(todosProvider(listId).notifier)
                    .create(title: title);
                if (!saved && context.mounted) {
                  AppToast.show(context, AppToast.saveFailed);
                }
              },
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
    required this.bottomPadding,
  });

  final String listId;
  final List<Todo> items;
  final double topPadding;
  final double bottomPadding;

  @override
  ConsumerState<_TodosList> createState() => _TodosListState();
}

class _TodosListState extends ConsumerState<_TodosList> {
  static const double _joinedGap = 2;

  /// A partir de este tamaño la lista vuelve a ser perezosa (sin animación
  /// de deslizamiento) para no mantener todas las filas montadas.
  static const int _maxGlideRows = 80;

  /// Tiempo que se mantiene el orden previo tras completar/desmarcar para
  /// que el tachado se reproduzca en el sitio donde se hizo el gesto.
  static const Duration _reorderDelay = Duration(milliseconds: 600);

  final _reveal = RevealProgress();

  late final _held = HeldReorder<Todo>(
    idOf: (todo) => todo.id,
    flagOf: (todo) => todo.isDone,
    onRelease: () {
      if (mounted) setState(() {});
    },
    delay: _reorderDelay,
  );


  void _setTileRevealProgress(String todoId, double progress) {
    setState(() => _reveal.set(todoId, progress));
  }

  @override
  void dispose() {
    _held.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(todosProvider(widget.listId).notifier);
    final completedToBottom = ref.watch(
      settingsOrDefaultsProvider.select((s) => s.completedToBottom),
    );

    final sorted = sortTodos(
      widget.items,
      completedToBottom: completedToBottom,
    );
    _reveal.retainOnly([for (final todo in widget.items) todo.id]);

    // Mantener el orden previo mientras se anima el tachado de un toggle.
    final displayItems = _held.resolve(items: widget.items, desired: sorted);

    // Listas muy largas: vuelta a la lista perezosa clásica (el tachado se
    // anima, pero sin deslizamiento a la nueva posición).
    if (displayItems.length > _maxGlideRows) {
      return ListView.separated(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          widget.topPadding,
          AppSpacing.lg,
          widget.bottomPadding,
        ),
        itemCount: displayItems.length,
        separatorBuilder: (_, _) => const SizedBox(height: _joinedGap),
        itemBuilder: (context, i) =>
            _buildTodoTile(context, ref, notifier, displayItems, i),
      );
    }

    final rows = <SlideRow>[];
    for (var i = 0; i < displayItems.length; i++) {
      rows.add(
        SlideRow(
          key: ValueKey(displayItems[i].id),
          spacingAfter: i < displayItems.length - 1 ? _joinedGap : 0,
          child: _buildTodoTile(context, ref, notifier, displayItems, i),
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        widget.topPadding,
        AppSpacing.lg,
        widget.bottomPadding,
      ),
      child: SlideFlow(rows: rows),
    );
  }

  Widget _buildTodoTile(
    BuildContext context,
    WidgetRef ref,
    TodosNotifier notifier,
    List<Todo> displayItems,
    int index,
  ) {
    final todo = displayItems[index];
    final separation = _reveal.separationFor(
      todo.id,
      previousId: index > 0 ? displayItems[index - 1].id : null,
      nextId: index < displayItems.length - 1 ? displayItems[index + 1].id : null,
    );
    return TodoTile(
      todo: todo,
      groupIndex: index,
      groupSize: displayItems.length,
      topSeparationProgress: separation.top,
      bottomSeparationProgress: separation.bottom,
      onRevealProgressChanged: (progress) =>
          _setTileRevealProgress(todo.id, progress),
      onTap: () => _showDetailSheet(context, ref, todo.id),
      onLongPress: () => context.push(Routes.todoEdit(widget.listId, todo.id)),
      onComplete: () async {
        final saved = await notifier.toggleDone(todo.id, !todo.isDone);
        if (!saved && context.mounted) {
          AppToast.show(context, AppToast.updateFailed);
        }
      },
      onDelete: () async {
        final deleted = await notifier.delete(todo.id);
        if (!context.mounted) return;

        if (deleted == null) {
          AppToast.show(context, AppToast.todoDeleteFailed);
          return;
        }
        AppToast.showUndo(
          context,
          message: AppToast.todoDeleted,
          onUndo: () => notifier.undo(deleted),
        );
      },
    );
  }

  void _showDetailSheet(BuildContext context, WidgetRef ref, String todoId) {
    ref.read(detailSheetOpenProvider.notifier).open();

    showModalBottomSheet<void>(
      context: context,
      // Montar el sheet sobre el shell mantiene el mismo comportamiento que
      // el detalle de citas y evita que la BottomBar quede por encima.
      useRootNavigator: true,
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
