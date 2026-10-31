import 'package:comfy_list/routing/routes.dart';
import 'package:comfy_list/routing/shell_layout.dart';
import 'package:comfy_list/shared/ui/navigation/app_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ShellLayout at(String path) => ShellLayout.forPath(path);

  group('el listado de listas', () {
    for (final path in [Routes.home, Routes.todoLists]) {
      test('$path es la pantalla de inicio', () {
        final layout = at(path);

        expect(layout.isLists, isTrue);
        expect(layout.isEditScreen, isFalse);
        expect(layout.showsBack, isFalse);
        expect(layout.hidesBottomBar, isFalse);
        expect(layout.activeTab, AppBottomTab.tasks);
        expect(layout.fab, (tooltip: 'Nueva lista', route: Routes.todoListNew));
      });
    }
  });

  group('las tareas de una lista', () {
    test('muestra la barra, vuelve atrás y crea tareas de esa lista', () {
      final layout = at(Routes.todoList('L1'));

      expect(layout.isListDetail, isTrue);
      expect(layout.listId, 'L1');
      expect(layout.showsBack, isTrue);
      expect(layout.hidesBottomBar, isFalse);
      expect(layout.activeTab, AppBottomTab.tasks);
      expect(
        layout.fab,
        (tooltip: 'Nueva tarea', route: Routes.todoNew('L1')),
      );
    });

    test('no confunde una lista llamada «new» ni «edit» con su pantalla', () {
      expect(at('/lists/new').isListDetail, isFalse);
      expect(at('/lists/L1/edit').isListDetail, isFalse);
    });
  });

  group('las citas', () {
    test('el listado usa la pestaña de citas y crea citas', () {
      final layout = at(Routes.appointments);

      expect(layout.isAppointments, isTrue);
      expect(layout.activeTab, AppBottomTab.appointments);
      expect(layout.hidesBottomBar, isFalse);
      expect(
        layout.fab,
        (tooltip: 'Nueva cita', route: Routes.appointmentNew),
      );
    });
  });

  group('las pantallas con título propio', () {
    final cases = <String, String>{
      Routes.todoListNew: 'Nueva lista',
      Routes.todoListEdit('L1'): 'Editar lista',
      Routes.todoNew('L1'): 'Nueva tarea',
      Routes.todoEdit('L1', 't1'): 'Editar tarea',
      Routes.appointmentNew: 'Nueva cita',
      Routes.appointmentEdit('a1'): 'Editar cita',
      Routes.settings: 'Ajustes',
      Routes.trash: 'Papelera',
    };

    cases.forEach((path, title) {
      test('$path se titula «$title», vuelve atrás y oculta la barra', () {
        final layout = at(path);

        expect(layout.editScreenTitle, title);
        expect(layout.isEditScreen, isTrue);
        expect(layout.showsBack, isTrue);
        expect(layout.hidesBottomBar, isTrue);
        expect(layout.fab, isNull);
      });
    });
  });

  group('las rutas dentro de una lista', () {
    test('crear y editar una tarea cuentan como anidadas', () {
      expect(at(Routes.todoNew('L1')).isNestedRoute, isTrue);
      expect(at(Routes.todoEdit('L1', 't1')).isNestedRoute, isTrue);
    });

    test('el detalle y el listado no lo son', () {
      expect(at(Routes.todoList('L1')).isNestedRoute, isFalse);
      expect(at(Routes.todoLists).isNestedRoute, isFalse);
    });

    test('«editar lista» está dentro de la lista y oculta la barra', () {
      final layout = at(Routes.todoListEdit('L1'));

      expect(layout.isNestedRoute, isTrue);
      expect(layout.hidesBottomBar, isTrue);
    });
  });

  test('una ruta que no conoce no pone título ni botón ni oculta la barra', () {
    final layout = at('/algo-que-no-existe');

    expect(layout.isLists, isFalse);
    expect(layout.isAppointments, isFalse);
    expect(layout.isListDetail, isFalse);
    expect(layout.editScreenTitle, isNull);
    expect(layout.fab, isNull);
    expect(layout.hidesBottomBar, isFalse);
    expect(layout.activeTab, AppBottomTab.tasks);
  });
}
