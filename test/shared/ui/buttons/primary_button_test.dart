import 'package:comfy_list/shared/core/theme/app_theme.dart';
import 'package:comfy_list/shared/ui/buttons/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpButton(
    WidgetTester tester, {
    VoidCallback? onPressed,
    bool dense = false,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Center(
            child: PrimaryButton(
              label: 'Añadir',
              onPressed: onPressed,
              dense: dense,
            ),
          ),
        ),
      ),
    );
  }

  /// La caja que pinta el botón —la que envuelve a su etiqueta—, con el relleno
  /// y el halo que le tocan.
  BoxDecoration buttonDecoration(WidgetTester tester) {
    final decorations = tester
        .widgetList<DecoratedBox>(
          find.ancestor(
            of: find.text('AÑADIR'),
            matching: find.byType(DecoratedBox),
          ),
        )
        .map((box) => box.decoration)
        .whereType<BoxDecoration>()
        .where((decoration) => decoration.color != null);
    return decorations.first;
  }

  testWidgets('con acción va en primary y con halo', (tester) async {
    await pumpButton(tester, onPressed: () {});

    final decoration = buttonDecoration(tester);
    expect(decoration.color, AppColors.light.primary);
    expect(decoration.boxShadow, isNotNull);
  });

  testWidgets('sin acción queda en muted y sin halo', (tester) async {
    await pumpButton(tester);

    final decoration = buttonDecoration(tester);
    expect(decoration.color, AppColors.light.muted);
    expect(decoration.boxShadow, isNull);
  });

  testWidgets('la etiqueta va en mayúsculas', (tester) async {
    await pumpButton(tester, onPressed: () {});

    expect(find.text('AÑADIR'), findsOneWidget);
  });

  testWidgets('dense deja el alto del botón secundario', (tester) async {
    await pumpButton(tester, onPressed: () {}, dense: true);
    final denseHeight = tester.getSize(find.byType(PrimaryButton)).height;

    await pumpButton(tester, onPressed: () {});
    final regularHeight = tester.getSize(find.byType(PrimaryButton)).height;

    expect(denseHeight, 44);
    expect(denseHeight, lessThan(regularHeight));
  });
}
