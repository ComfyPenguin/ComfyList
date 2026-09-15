import 'package:comfy_list/features/todo_lists/domain/entities/todo_list.dart';
import 'package:comfy_list/features/todo_lists/presentation/providers/todo_lists_provider.dart';
import 'package:comfy_list/features/todo_lists/presentation/providers/todo_lists_state.dart';
import 'package:comfy_list/features/todo_lists/presentation/screens/todo_list_edit_screen.dart';
import 'package:comfy_list/features/todo_lists/presentation/widgets/icon_picker.dart';
import 'package:comfy_list/shared/core/theme/app_theme.dart';
import 'package:comfy_list/shared/ui/inputs/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_helpers.dart';

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

  Future<void> pumpScreen(
    WidgetTester tester, {
    Size physicalSize = const Size(1170, 2400),
  }) async {
    tester.view.physicalSize = physicalSize;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todoListsProvider.overrideWith(
            () => _FixedLists([buildTodoList(id: 'L1')]),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const TodoListEditScreen(),
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
    // Y los iconos del selector caben: doce en el ancho de un móvil estrecho.
    expect(find.byType(IconPicker), findsOneWidget);
    expect(tester.getSize(find.byType(AppTextField)).width, 288);
  });
}
