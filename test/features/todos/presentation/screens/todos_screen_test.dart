import 'package:comfy_list/features/settings/presentation/providers/settings_provider.dart';
import 'package:comfy_list/features/todos/domain/entities/todo.dart';
import 'package:comfy_list/features/todos/presentation/providers/todos_provider.dart';
import 'package:comfy_list/features/todos/presentation/providers/todos_state.dart';
import 'package:comfy_list/features/todos/presentation/screens/todos_screen.dart';
import 'package:comfy_list/features/todos/presentation/widgets/quick_add_bar.dart';
import 'package:comfy_list/shared/core/theme/app_spacing.dart';
import 'package:comfy_list/shared/core/theme/app_theme.dart';
import 'package:comfy_list/shared/core/time/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../../../helpers/fake_settings_repository.dart';
import '../../../../helpers/test_helpers.dart';

class _FixedTodos extends TodosNotifier {
  _FixedTodos(this.items, {String listId = 'L1'}) : super(listId);

  final List<Todo> items;

  @override
  TodosState build() => TodosData(items);
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('es_ES');
    final loader = FontLoader('PlusJakartaSans')
      ..addFont(
        rootBundle.load('assets/fonts/PlusJakartaSans-VariableFont.ttf'),
      );
    await loader.load();
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    required List<Todo> items,
    Size physicalSize = const Size(1170, 2400),
  }) async {
    final repo = FakeSettingsRepository();
    addTearDown(repo.close);

    tester.view.physicalSize = physicalSize;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todosProvider('L1').overrideWith(() => _FixedTodos(items)),
          settingsRepositoryProvider.overrideWithValue(repo),
          clockProvider.overrideWithValue(() => DateTime(2026, 9, 15, 10)),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          // El Scaffold lo pone el shell en la app; el campo de la barra rápida
          // necesita un Material encima.
          home: const Scaffold(body: TodosScreen(listId: 'L1')),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('en un móvil estrecho con títulos largos no desborda', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      // 320 x 640 lógicos: lo más estrecho que se sigue usando.
      physicalSize: const Size(960, 1920),
      items: [
        buildTodo(
          id: 't1',
          title:
              'Preparar la presentación del trimestre con las cifras de '
              'ventas y el resumen de incidencias',
        ),
        buildTodo(id: 't2', title: 'Comprar pan'),
      ],
    );

    // Un desborde llega aquí como excepción: no haberla es la comprobación.
    expect(tester.takeException(), isNull);
  });

  testWidgets('la barra de añadir mide su alto y no se estira', (tester) async {
    await pumpScreen(tester, items: [buildTodo(id: 't1')]);

    final bar = tester.getRect(find.byType(QuickAddBar));
    final screen = tester.getSize(find.byType(Scaffold)).height;

    expect(bar.height, 48);
    // Flota por encima de donde va el dock (72 + su margen), no pegada al borde.
    expect(bar.bottom, lessThanOrEqualTo(screen - 72 - AppSpacing.lg));
  });
}
