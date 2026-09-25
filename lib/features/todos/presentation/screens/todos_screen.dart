import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../routing/routes.dart';
import '../../../../shared/core/theme/app_spacing.dart';
import '../../../../shared/core/theme/app_theme.dart';
import '../../../../shared/core/theme/app_typography.dart';
import '../../../../shared/ui/lists/slide_flow.dart';
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
              onSubmit: (title) =>
                  ref.read(todosProvider(listId).notifier).create(title: title),
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

  final _tileRevealProgress = <String, double>{};

  // Orden visual mostrado en el último build (ids), los items previos y si
  // se está retrasando el reordenado tras un cambio de isDone.
  List<String>? _displayedIds;
  List<Todo>? _lastItems;
  bool _holdingReorder = false;
  Timer? _reorderTimer;

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
  void dispose() {
    _reorderTimer?.cancel();
    super.dispose();
  }

  bool _sameIds(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Compara como conjunto (sin importar el orden del provider): solo nos
  /// importa que no haya altas/borrados para poder reordenar manteniendo
  /// los ids mostrados.
  bool _sameIdSet(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    final bSet = b.toSet();
    for (final id in a) {
      if (!bSet.contains(id)) return false;
    }
    return true;
  }

  /// Devuelve el orden a mostrar: si un único item acaba de cambiar de
  /// [Todo.isDone] y eso reordenaría la lista, mantiene el orden anterior
  /// durante [_reorderDelay] para no cortar la animación del tachado.
  List<Todo> _resolveDisplayItems(List<Todo> desired) {
    final items = widget.items;
    final currentIds = [for (final t in items) t.id];
    final previous = _lastItems;
    _lastItems = items;

    // Detectar si exactamente un item cambió de isDone desde el último build.
    String? toggledId;
    if (previous != null) {
      final prevById = {for (final t in previous) t.id: t};
      var flips = 0;
      for (final t in items) {
        final p = prevById[t.id];
        if (p != null && p.isDone != t.isDone) {
          toggledId = t.id;
          flips++;
        }
      }
      if (flips != 1) toggledId = null;
    }

    final canKeepLayout =
        _displayedIds != null && _sameIdSet(_displayedIds!, currentIds);
    final desiredIds = [for (final t in desired) t.id];
    final wouldReorder =
        toggledId != null &&
        canKeepLayout &&
        !_sameIds(_displayedIds!, desiredIds);

    if (wouldReorder && !_holdingReorder) {
      _holdingReorder = true;
      _reorderTimer?.cancel();
      _reorderTimer = Timer(_reorderDelay, () {
        if (!mounted) return;
        setState(() => _holdingReorder = false);
      });
    }

    if (_holdingReorder) {
      if (canKeepLayout) {
        final byId = {for (final t in items) t.id: t};
        return [for (final id in _displayedIds!) byId[id]!];
      }
      // El conjunto de ids cambió (alta/borrado): reordenar ya.
      _holdingReorder = false;
      _reorderTimer?.cancel();
      _reorderTimer = null;
    }

    _displayedIds = desiredIds;
    return desired;
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(todosProvider(widget.listId).notifier);
    final completedToBottom = switch (ref.watch(settingsProvider)) {
      SettingsData(:final settings) => settings.completedToBottom,
      _ => true,
    };

    // Ordenar según el ajuste:
    // - Activado: pendientes primero por fecha de actualización asc (lo
    //   recién desmarcado cae al final, junto a las completadas); completadas
    //   después por fecha de actualización desc.
    // - Desactivado: por fecha de creación asc (mantiene la posición siempre).
    final sorted = [...widget.items]
      ..sort((a, b) {
        if (completedToBottom) {
          if (a.isDone != b.isDone) return a.isDone ? 1 : -1;
          if (a.isDone) return b.updatedAt.compareTo(a.updatedAt);
          return a.updatedAt.compareTo(b.updatedAt);
        }
        return a.createdAt.compareTo(b.createdAt);
      });
    _removeStaleRevealProgress(widget.items);

    // Mantener el orden previo mientras se anima el tachado de un toggle.
    final displayItems = _resolveDisplayItems(sorted);

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
    final separation = _effectiveSeparationFor(index, displayItems);
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
      onComplete: () => notifier.toggleDone(todo.id, !todo.isDone),
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
