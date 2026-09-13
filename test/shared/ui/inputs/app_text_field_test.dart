import 'package:comfy_list/shared/core/theme/app_theme.dart';
import 'package:comfy_list/shared/ui/inputs/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpField(
    WidgetTester tester,
    TextEditingController controller,
  ) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: AppTextField(
            controller: controller,
            label: 'Nombre',
            cardStyle: true,
          ),
        ),
      ),
    );
  }

  group('AppTextField etiqueta', () {
    testWidgets('dentro del campo se queda como placeholder', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await pumpField(tester, controller);

      expect(find.text('Nombre'), findsOneWidget);
      expect(find.text('NOMBRE'), findsNothing);
    });

    testWidgets('al subir al borde pasa a mayúsculas', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await pumpField(tester, controller);
      await tester.tap(find.byType(TextField));
      await tester.pump();

      expect(find.text('NOMBRE'), findsOneWidget);
    });

    testWidgets('con texto y sin foco sigue en mayúsculas', (tester) async {
      final controller = TextEditingController(text: 'Compra');
      addTearDown(controller.dispose);

      await pumpField(tester, controller);

      expect(find.text('NOMBRE'), findsOneWidget);
    });

    testWidgets('vuelve al placeholder al vaciar el campo', (tester) async {
      final controller = TextEditingController(text: 'Compra');
      addTearDown(controller.dispose);

      await pumpField(tester, controller);
      controller.clear();
      await tester.pump();

      expect(find.text('Nombre'), findsOneWidget);
      expect(find.text('NOMBRE'), findsNothing);
    });

    testWidgets('el ciclo foco, escritura y vaciado no rompe nada', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await pumpField(tester, controller);

      await tester.tap(find.byType(TextField));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'Compra semanal');
      await tester.pumpAndSettle();
      expect(find.text('NOMBRE'), findsOneWidget);

      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      expect(find.text('NOMBRE'), findsOneWidget);

      controller.clear();
      await tester.pumpAndSettle();
      expect(find.text('Nombre'), findsOneWidget);
      expect(find.byType(ErrorWidget), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
