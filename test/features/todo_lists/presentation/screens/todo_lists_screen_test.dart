import 'package:comfy_list/features/todo_lists/domain/entities/todo_list.dart';
import 'package:comfy_list/features/todo_lists/presentation/providers/todo_lists_provider.dart';
import 'package:comfy_list/features/todo_lists/presentation/providers/todo_lists_state.dart';
import 'package:comfy_list/features/settings/presentation/providers/settings_provider.dart';
import 'package:comfy_list/features/todo_lists/presentation/screens/todo_lists_screen.dart';
import 'package:comfy_list/routing/routes.dart';
import 'package:comfy_list/shared/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fake_settings_repository.dart';
import '../../../../helpers/test_helpers.dart';
import '../../../../helpers/test_router.dart';

class _FixedLists extends TodoListsNotifier {
  _FixedLists(this.items);

  final List<TodoList> items;

  @override
  TodoListsState build() => TodoListsData(items);
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final loader = FontLoader('PlusJakartaSans')
      ..addFont(
        rootBundle.load('assets/fonts/PlusJakartaSans-VariableFont.ttf'),
      );
    await loader.load();
  });

  const longName = 'Compra semanal del supermercado';
  const hintText = 'Mantén pulsada para editar.';

  Future<void> pumpScreen(
    WidgetTester tester, {
    Size physicalSize = const Size(1170, 2400),
    // Por defecto la pista ya está vista: así no interfiere en los demás tests.
    FakeSettingsRepository? settings,
  }) async {
    final repo =
        settings ??
        FakeSettingsRepository(
          settings: buildAppSettings(longPressHintSeen: true),
        );
    addTearDown(repo.close);

    tester.view.physicalSize = physicalSize;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todoListsProvider.overrideWith(
            () => _FixedLists([
              buildTodoList(id: 'L1', name: longName),
              buildTodoList(id: 'L2', name: 'Casa'),
            ]),
          ),
          settingsRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const TodoListsScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('en un móvil estrecho el nombre largo cabe en su fila', (
    tester,
  ) async {
    // 320 x 640 lógicos: lo más estrecho que se sigue usando.
    await pumpScreen(tester, physicalSize: const Size(960, 1920));

    // Un desborde llega aquí como excepción: no haberla es la comprobación.
    expect(tester.takeException(), isNull);
    expect(tester.getRect(find.text(longName)).right, lessThanOrEqualTo(320));
  });

  Future<void> pumpRouted(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todoListsProvider.overrideWith(
            () => _FixedLists([
              buildTodoList(id: 'L1', name: longName),
              buildTodoList(id: 'L2', name: 'Casa'),
            ]),
          ),
          settingsRepositoryProvider.overrideWithValue(
            FakeSettingsRepository(
              settings: buildAppSettings(longPressHintSeen: true),
            ),
          ),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: buildTestRouter(
            initialLocation: Routes.todoLists,
            home: const TodoListsScreen(),
            probes: {Routes.todoListEdit('L1'): 'EDITAR LISTA L1'},
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('mantener pulsada una lista abre su pantalla de edición', (
    tester,
  ) async {
    await pumpRouted(tester);

    await tester.longPress(find.text(longName));
    await tester.pump();

    expect(find.text('EDITAR LISTA L1'), findsOneWidget);
  });

  testWidgets('la primera visita muestra la pista y la marca como vista', (
    tester,
  ) async {
    final repo = FakeSettingsRepository();
    await pumpScreen(tester, settings: repo);

    expect(find.text(hintText), findsOneWidget);
    expect((await repo.load()).longPressHintSeen, isTrue);

    // Deja que el aviso se oculte solo y no quede su temporizador pendiente.
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
  });

  testWidgets('con la pista ya vista no vuelve a aparecer', (tester) async {
    await pumpScreen(
      tester,
      settings: FakeSettingsRepository(
        settings: buildAppSettings(longPressHintSeen: true),
      ),
    );

    expect(find.text(hintText), findsNothing);
  });
}
