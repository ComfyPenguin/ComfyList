import 'package:comfy_list/features/todo_lists/presentation/providers/todo_lists_provider.dart';
import 'package:comfy_list/features/todo_lists/presentation/providers/todo_lists_state.dart';
import 'package:comfy_list/routing/routes.dart';
import 'package:comfy_list/shared/core/theme/app_theme.dart';
import 'package:comfy_list/shared/ui/navigation/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../helpers/provider_scope.dart';
import '../../../helpers/test_helpers.dart';

/// Listas ya cargadas: el shell solo las mira para titular el detalle.
class _LoadedLists extends TodoListsNotifier {
  @override
  TodoListsState build() => TodoListsData([buildTodoList(id: 'L1', name: 'Compras')]);
}

void main() {
  Future<void> pumpAt(WidgetTester tester, String location) async {
    tester.view.physicalSize = const Size(1170, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: location,
      routes: [
        ShellRoute(
          builder: (context, state, child) =>
              AppShell(routerState: state, child: child),
          routes: [
            GoRoute(
              path: '/:rest(.*)',
              builder: (_, _) => const SizedBox.shrink(),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    final container = createTestContainer(
      withInMemoryDb: true,
      authedUser: buildAuthUser(),
      extra: [todoListsProvider.overrideWith(_LoadedLists.new)],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('el listado enseña el nombre de la app y el botón de nueva lista',
      (tester) async {
    await pumpAt(tester, Routes.todoLists);

    expect(find.text('ComfyList'), findsWidgets);
    expect(find.byTooltip('Nueva lista'), findsOneWidget);
    expect(find.byTooltip('Cerrar sesión'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('el detalle de una lista se titula con su nombre y vuelve atrás',
      (tester) async {
    await pumpAt(tester, Routes.todoList('L1'));

    expect(find.text('Compras'), findsWidgets);
    expect(find.byTooltip('Nueva tarea'), findsOneWidget);
    expect(find.byTooltip('Volver'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('una pantalla de edición lleva su título y no tiene botón de acción',
      (tester) async {
    await pumpAt(tester, Routes.todoNew('L1'));

    expect(find.text('Nueva tarea'), findsWidgets);
    expect(find.byTooltip('Volver'), findsOneWidget);
    expect(find.byTooltip('Nueva tarea'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('las citas muestran su botón de nueva cita', (tester) async {
    await pumpAt(tester, Routes.appointments);

    expect(find.byTooltip('Nueva cita'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
