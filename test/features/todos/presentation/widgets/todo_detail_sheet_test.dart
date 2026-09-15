import 'package:comfy_list/features/settings/presentation/providers/settings_provider.dart';
import 'package:comfy_list/features/todos/presentation/providers/todos_provider.dart';
import 'package:comfy_list/features/todos/presentation/providers/todos_state.dart';
import 'package:comfy_list/features/todos/presentation/widgets/todo_detail_sheet.dart';
import 'package:comfy_list/shared/core/failures/failure.dart';
import 'package:comfy_list/shared/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fake_settings_repository.dart';

class _FixedTodos extends TodosNotifier {
  _FixedTodos(this._state) : super('L1');

  final TodosState _state;

  @override
  TodosState build() => _state;
}

void main() {
  /// Tope que el sheet se pone a sí mismo: el 85 % de la pantalla del test.
  const cap = 600 * 0.85;

  Future<void> pumpSheet(WidgetTester tester, TodosState state) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todosProvider('L1').overrideWith(() => _FixedTodos(state)),
          settingsRepositoryProvider.overrideWithValue(
            FakeSettingsRepository(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: TodoDetailSheet(listId: 'L1', todoId: 't1', onEdit: () {}),
          ),
        ),
      ),
    );
  }

  double sheetHeight(WidgetTester tester) =>
      tester.getSize(find.byType(TodoDetailSheet)).height;

  testWidgets('cargando mide lo que el spinner', (tester) async {
    await pumpSheet(tester, const TodosLoading());

    expect(sheetHeight(tester), lessThan(cap));
  });

  testWidgets('el error mide lo que el mensaje', (tester) async {
    await pumpSheet(
      tester,
      const TodosError(UnknownFailure('No se pudieron cargar.')),
    );

    expect(sheetHeight(tester), lessThan(cap));
  });

  testWidgets('la tarea eliminada mide lo que el mensaje', (tester) async {
    await pumpSheet(tester, const TodosData([]));

    expect(sheetHeight(tester), lessThan(cap));
  });
}
