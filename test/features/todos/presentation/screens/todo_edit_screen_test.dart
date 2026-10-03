import 'package:comfy_list/features/todos/presentation/providers/todos_provider.dart';
import 'package:comfy_list/features/todos/presentation/providers/todos_state.dart';
import 'package:comfy_list/features/todos/presentation/screens/todo_edit_screen.dart';
import 'package:comfy_list/shared/core/theme/app_theme.dart';
import 'package:comfy_list/shared/ui/inputs/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _EmptyTodos extends TodosNotifier {
  _EmptyTodos() : super('L1');

  @override
  TodosState build() => TodosData(const []);
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

  Future<void> pumpScreen(
    WidgetTester tester, {
    Size physicalSize = const Size(1170, 2400),
  }) async {
    tester.view.physicalSize = physicalSize;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [todosProvider('L1').overrideWith(_EmptyTodos.new)],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const TodoEditScreen(listId: 'L1'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('en un móvil estrecho no desborda', (tester) async {
    // 320 x 640 lógicos: lo más estrecho que se sigue usando.
    await pumpScreen(tester, physicalSize: const Size(960, 1920));

    // Un desborde llega aquí como excepción: no haberla es la comprobación.
    expect(tester.takeException(), isNull);
    // Los dos campos ocupan el ancho del formulario, con su sangrado.
    expect(
      tester.widgetList<AppTextField>(find.byType(AppTextField)),
      hasLength(2),
    );
    expect(tester.getSize(find.byType(AppTextField).first).width, 288);
  });
}
