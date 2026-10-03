import 'package:comfy_list/shared/core/theme/app_theme.dart';
import 'package:comfy_list/shared/ui/inputs/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpField(
    WidgetTester tester,
    TextEditingController controller, {
    String label = 'Nombre',
    bool obscureText = false,
    Iterable<String>? autofillHints,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: AppTextField(
            controller: controller,
            label: label,
            cardStyle: true,
            obscureText: obscureText,
            autofillHints: autofillHints,
          ),
        ),
      ),
    );
  }

  group('AppTextField y el teclado', () {
    testWidgets('un campo normal sí autocorrige', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await pumpField(tester, controller);

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.autocorrect, isTrue);
      expect(field.enableSuggestions, isTrue);
    });

    testWidgets('uno de contraseña no autocorrige ni sugiere', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await pumpField(
        tester,
        controller,
        label: 'Contraseña',
        obscureText: true,
        autofillHints: const [AutofillHints.newPassword],
      );

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.autocorrect, isFalse);
      expect(field.enableSuggestions, isFalse);
      // Y el gestor de contraseñas sabe qué le toca rellenar.
      expect(field.autofillHints, [AutofillHints.newPassword]);
    });
  });

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

    testWidgets('en el borde solo sube el título, sin el (opcional)', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await pumpField(tester, controller, label: 'Notas (opcional)');
      expect(find.text('Notas (opcional)'), findsOneWidget);

      await tester.tap(find.byType(TextField));
      await tester.pump();

      expect(find.text('NOTAS'), findsOneWidget);
      expect(find.textContaining('OPCIONAL'), findsNothing);
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
