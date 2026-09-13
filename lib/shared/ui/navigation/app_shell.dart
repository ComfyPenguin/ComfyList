import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:marquee/marquee.dart';

import '../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../features/todo_lists/domain/entities/todo_list.dart';
import '../../../features/todo_lists/presentation/providers/todo_lists_provider.dart';
import '../../../features/todo_lists/presentation/providers/todo_lists_state.dart';
import '../../../routing/routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../dialogs/confirm_action_dialog.dart';
import 'app_bottom_bar.dart';

/// Notifier que gestiona si un bottom sheet de detalle está abierto.
/// Cuando está activo, el AppShell oculta la BottomBar para que no se
/// superponga al contenido del sheet, pero conserva el AppBar superior.
class DetailSheetOpenNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void open() => state = true;
  void close() => state = false;
}

/// Expone al contenido del shell si el teclado está visible.
///
/// El [Scaffold] puede eliminar el `viewInsets` del teclado al calcular las
/// constraints del `body`. En ese caso, las pantallas hijas no pueden detectar
/// el teclado únicamente desde su propio `MediaQuery`.
class KeyboardVisibilityScope extends InheritedWidget {
  const KeyboardVisibilityScope({
    super.key,
    required this.bottomInset,
    required super.child,
  });

  final double bottomInset;

  static double bottomInsetOf(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<KeyboardVisibilityScope>()
            ?.bottomInset ??
        0.0;
  }

  @override
  bool updateShouldNotify(KeyboardVisibilityScope oldWidget) {
    return bottomInset != oldWidget.bottomInset;
  }
}

final detailSheetOpenProvider = NotifierProvider<DetailSheetOpenNotifier, bool>(
  DetailSheetOpenNotifier.new,
);

/// Shell persistente de la app: AppBar, BottomBar y FAB compartidos.
///
/// Las rutas hijas se renderizan en el [body] del Scaffold. El AppBar muestra
/// el botón de cerrar sesión a la izquierda y el botón de ajustes a la derecha.
///
/// `routerState` viene del builder del `ShellRoute` y representa la ruta hija
/// activa (no la del shell), así el FAB sabe si estamos en
/// `/lists`, `/lists/:id` o `/appointments`.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.routerState, required this.child});

  final GoRouterState routerState;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // `uri.path` siempre refleja la URL completa actual; `matchedLocation`
    // dentro de un ShellRoute representa solo el segmento de la propia shell,
    // por lo que detectar `/lists/:id` requiere mirar el path real.
    final location = routerState.uri.path;
    final colors = context.colors;
    final isDark = colors.canvas.computeLuminance() < 0.05;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final isLists = location == Routes.todoLists || location == Routes.home;
    final isListEdit =
        location == Routes.todoListNew ||
        RegExp(r'^/lists/[^/]+/edit$').hasMatch(location);
    final isListDetail =
        !isListEdit && RegExp(r'^/lists/[^/]+$').hasMatch(location);
    final isAppointments = location == Routes.appointments;

    // ── Pantallas de edición dentro del shell ──
    // Conservan el TopBar con el nombre de la pantalla como título y ocultan
    // la BottomBar.
    final isTodoEdit =
        RegExp(r'^/lists/[^/]+/todos/(new|[^/]+)$').hasMatch(location);
    final editScreenTitle = switch (location) {
      Routes.todoListNew => 'Nueva lista',
      _ when isListEdit => 'Editar lista',
      _ when location.endsWith('/todos/new') => 'Nueva tarea',
      _ when isTodoEdit => 'Editar tarea',
      _ => null,
    };

    // ── Rutas anidadas dentro de una lista ──
    // Las pantallas anidadas (creación y edición de tarea) ocultan la
    // BottomBar para dar una experiencia full-screen.
    final isNestedRoute = RegExp(r'^/lists/[^/]+/.+').hasMatch(location);

    // ── Sheet de detalle abierto: ocultar FAB y BottomBar ──
    // Evita que el FAB (80 px) y la barra de navegación se superpongan
    // al contenido del bottom sheet modal.
    final isDetailSheetOpen = ref.watch(detailSheetOpenProvider);

    // ── FAB: solo en listas y tareas (integrado en la bottom bar) ──
    VoidCallback? onFabTap;
    String? fabTooltip;
    if (isLists) {
      fabTooltip = 'Nueva lista';
      onFabTap = () => context.push(Routes.todoListNew);
    } else if (isListDetail) {
      final listId = location.split('/').last;
      fabTooltip = 'Nueva tarea';
      onFabTap = () => context.push(Routes.todoNew(listId));
    } else if (isAppointments) {
      fabTooltip = 'Nueva cita';
      onFabTap = () => context.push(Routes.appointmentNew);
    }

    // ── Título del AppBar ──
    // En las pantallas de edición mostramos el nombre de la pantalla, dentro
    // de una lista concreta (/lists/:id) el nombre de la lista y, en el resto,
    // el nombre de la app.
    String appBarTitle = 'ComfyList';
    if (editScreenTitle != null) {
      appBarTitle = editScreenTitle;
    } else if (isListDetail) {
      final listId = location.split('/').last;
      final listsState = ref.watch(todoListsProvider);
      if (listsState is TodoListsData) {
        final list = listsState.items.cast<TodoList?>().firstWhere(
          (l) => l?.id == listId,
          orElse: () => null,
        );
        if (list != null) {
          appBarTitle = list.name;
        }
      }
    }

    // ── BottomBar: pestaña activa según la ruta ──
    final activeTab = isAppointments
        ? AppBottomTab.appointments
        : AppBottomTab.tasks;

    // El TopBar se mantiene siempre visible dentro del shell —también sobre
    // los bottom sheets de detalle—; la BottomBar se oculta en las pantallas
    // de detalle/edición y mientras hay un sheet de detalle abierto.
    final isEditScreen = editScreenTitle != null;
    final hideBottomBar = isNestedRoute || isDetailSheetOpen || isEditScreen;

    return Scaffold(
      // El shell usa overlays posicionados manualmente. Mantener el body a
      // pantalla completa permite que el contenido calcule la posición del
      // QuickAddBar usando el inset real del teclado.
      resizeToAvoidBottomInset: false,
      appBar: null,
      body: Stack(
        children: [
          KeyboardVisibilityScope(bottomInset: keyboardInset, child: child),
          // ── AppBar superior anclado ──
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(24),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top,
                    bottom: AppSpacing.sm,
                    left: AppSpacing.lg,
                    right: AppSpacing.lg,
                  ),
                  decoration: BoxDecoration(
                    color: colors.canvas.withValues(alpha: 0.7),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(24),
                    ),
                    border: Border(
                      left: BorderSide(
                        color: isDark
                            ? colors.ink.withValues(alpha: 0.18)
                            : colors.ink.withValues(alpha: 0.12),
                        width: 1.2,
                      ),
                      right: BorderSide(
                        color: isDark
                            ? colors.ink.withValues(alpha: 0.18)
                            : colors.ink.withValues(alpha: 0.12),
                        width: 1.2,
                      ),
                      bottom: BorderSide(
                        color: isDark
                            ? colors.ink.withValues(alpha: 0.18)
                            : colors.ink.withValues(alpha: 0.12),
                        width: 1.2,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (isListDetail || isEditScreen)
                        IconButton(
                          icon: Icon(
                            Icons.arrow_back_rounded,
                            color: colors.ink,
                            size: 22,
                          ),
                          tooltip: 'Volver',
                          onPressed: () {
                            // En creación/edición volvemos a la pantalla que
                            // nos abrió (la lista o el listado de listas).
                            if (isEditScreen && context.canPop()) {
                              context.pop();
                            } else {
                              context.go(Routes.todoLists);
                            }
                          },
                        )
                      else
                        IconButton(
                          icon: Icon(
                            Icons.logout_outlined,
                            color: colors.error,
                            size: 22,
                          ),
                          tooltip: 'Cerrar sesión',
                          onPressed: () async {
                            final confirmed = await ConfirmActionDialog.show(
                              context,
                              title: 'Cerrar sesión',
                              message: '¿Seguro que quieres cerrar la sesión?',
                              confirmLabel: 'Cerrar sesión',
                              destructive: true,
                            );
                            if (confirmed && context.mounted) {
                              ref.read(authProvider.notifier).signOut();
                            }
                          },
                        ),
                      Expanded(
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                'assets/logo-no-text-background.png',
                                width: 24,
                                height: 24,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Flexible(
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final titleStyle = AppTypography.displaySm
                                        .copyWith(color: colors.ink);
                                    // Solo animamos si el título desborda; con
                                    // un nombre corto el marquee scrollaría en
                                    // bucle innecesariamente.
                                    final titleWidth = _measureTitleWidth(
                                      appBarTitle,
                                      titleStyle,
                                      MediaQuery.textScalerOf(context),
                                    );
                                    final overflows =
                                        titleWidth > constraints.maxWidth;
                                    if (!overflows) {
                                      return Text(
                                        appBarTitle,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: titleStyle,
                                      );
                                    }
                                    // El marquee es un viewport horizontal y
                                    // necesita altura acotada; sin ella falla
                                    // el layout y el título desaparece.
                                    final titleLineHeight =
                                        titleStyle.fontSize! *
                                        (titleStyle.height ?? 1.0);
                                    return SizedBox(
                                      height: titleLineHeight,
                                      child: Marquee(
                                        text: appBarTitle,
                                        style: titleStyle,
                                        blankSpace: AppSpacing.xxxxl,
                                        velocity: 30,
                                        pauseAfterRound: const Duration(
                                          seconds: 2,
                                        ),
                                        startPadding: AppSpacing.md,
                                        fadingEdgeStartFraction: 0.15,
                                        fadingEdgeEndFraction: 0.15,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.settings_outlined,
                          color: colors.ink,
                          size: 22,
                        ),
                        tooltip: 'Ajustes',
                        onPressed: () => context.push(Routes.settings),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // ── BottomBar flotante inferior ──
          // Se mantiene montada detrás del teclado para evitar que aparezca
          // de golpe cuando el teclado se cierra.
          if (!hideBottomBar)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AppBottomBar(
                activeTab: activeTab,
                onTasksTap: () {
                  if (!isLists) context.go(Routes.todoLists);
                },
                onAppointmentsTap: () {
                  if (!isAppointments) context.go(Routes.appointments);
                },
                onFabTap: onFabTap,
                fabTooltip: fabTooltip,
                visible: !hideBottomBar,
              ),
            ),
        ],
      ),
    );
  }

  /// Mide el ancho intrínseco del título para decidir si desborda
  /// y toca usar marquee en lugar de texto estático con ellipsis.
  double _measureTitleWidth(
    String text,
    TextStyle style,
    TextScaler textScaler,
  ) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
    )..layout();
    return textPainter.width;
  }
}
