import '../shared/ui/navigation/app_bottom_bar.dart';
import 'routes.dart';

/// Qué enseña el shell para una ruta: título, botón de acción, pestaña activa y
/// si la barra de abajo está o no. Sale solo de la ruta, así que se puede probar
/// sin árbol de widgets; el shell añade lo que depende del estado (el nombre de
/// la lista, si hay una hoja de detalle abierta).
///
/// `path` es la URL completa (`routerState.uri.path`): dentro de un `ShellRoute`
/// `matchedLocation` solo trae el segmento del propio shell.
class ShellLayout {
  const ShellLayout._({
    required this.isLists,
    required this.isAppointments,
    required this.listId,
    required this.editScreenTitle,
    required this.isNestedRoute,
  });

  factory ShellLayout.forPath(String path) {
    final isListEdit =
        path == Routes.todoListNew || _listEdit.hasMatch(path);
    final isListDetail = !isListEdit && _listDetail.hasMatch(path);

    final editScreenTitle = switch (path) {
      Routes.todoListNew => 'Nueva lista',
      Routes.appointmentNew => 'Nueva cita',
      _ when isListEdit => 'Editar lista',
      _ when _todoNew.hasMatch(path) => 'Nueva tarea',
      _ when _todoEdit.hasMatch(path) => 'Editar tarea',
      _ when _appointmentEdit.hasMatch(path) => 'Editar cita',
      Routes.settings => 'Ajustes',
      Routes.trash => 'Papelera',
      _ => null,
    };

    return ShellLayout._(
      isLists: path == Routes.todoLists || path == Routes.home,
      isAppointments: path == Routes.appointments,
      listId: isListDetail ? path.split('/').last : null,
      editScreenTitle: editScreenTitle,
      isNestedRoute: _nested.hasMatch(path),
    );
  }

  static final _listEdit = RegExp(r'^/lists/[^/]+/edit$');
  static final _listDetail = RegExp(r'^/lists/[^/]+$');
  static final _todoNew = RegExp(r'^/lists/[^/]+/todos/new$');
  static final _todoEdit = RegExp(r'^/lists/[^/]+/todos/[^/]+$');
  static final _appointmentEdit = RegExp(r'^/appointments/[^/]+/edit$');
  static final _nested = RegExp(r'^/lists/[^/]+/.+');

  /// El listado de listas (la pantalla de inicio).
  final bool isLists;

  final bool isAppointments;

  /// Las tareas de una lista concreta: aquí está su id; en otra ruta, `null`.
  final String? listId;

  /// Título de las pantallas de creación, edición, ajustes y papelera; `null`
  /// en las demás.
  final String? editScreenTitle;

  /// Una ruta dentro de una lista (crear o editar una tarea).
  final bool isNestedRoute;

  bool get isListDetail => listId != null;

  bool get isEditScreen => editScreenTitle != null;

  /// Se vuelve atrás desde el detalle de una lista y desde las pantallas de
  /// edición; en el resto, el botón de la esquina cierra la sesión.
  bool get showsBack => isListDetail || isEditScreen;

  /// La barra de abajo se oculta en las pantallas de detalle y edición. El
  /// shell la oculta además mientras hay una hoja de detalle abierta.
  bool get hidesBottomBar => isNestedRoute || isEditScreen;

  AppBottomTab get activeTab =>
      isAppointments ? AppBottomTab.appointments : AppBottomTab.tasks;

  /// El botón de acción de la barra de abajo, o `null` donde no hay.
  ({String tooltip, String route})? get fab {
    if (isLists) return (tooltip: 'Nueva lista', route: Routes.todoListNew);
    if (isListDetail) {
      return (tooltip: 'Nueva tarea', route: Routes.todoNew(listId!));
    }
    if (isAppointments) {
      return (tooltip: 'Nueva cita', route: Routes.appointmentNew);
    }
    return null;
  }
}
