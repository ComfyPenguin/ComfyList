import 'package:comfy_list/features/appointments/presentation/widgets/reminder_lead_picker.dart';
import 'package:comfy_list/shared/core/theme/app_theme.dart';
import 'package:comfy_list/shared/ui/pickers/wheel_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Lo que devolvió el selector, que llega cuando el sheet se cierra.
class _Result {
  int? minutes;
  bool opened = false;
}

/// Pantalla mínima con un botón que abre el selector que le pidan.
class _Host extends StatelessWidget {
  const _Host({required this.onOpen});

  final void Function(BuildContext context) onOpen;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.light(),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => onOpen(context),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );
  }
}

void main() {
  /// Abre el selector y deja el test delante del sheet, para tocarlo.
  Future<_Result> open(
    WidgetTester tester, {
    required int initialMinutes,
  }) async {
    final result = _Result();
    await tester.pumpWidget(
      _Host(
        onOpen: (context) async {
          result.opened = true;
          result.minutes = await showReminderLeadPicker(
            context,
            initialMinutes: initialMinutes,
          );
        },
      ),
    );

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    return result;
  }

  Future<void> accept(WidgetTester tester) async {
    await tester.tap(find.text('ACEPTAR'));
    await tester.pumpAndSettle();
  }

  testWidgets('abre en minutos con el margen que ya había', (tester) async {
    final result = await open(tester, initialMinutes: 45);

    expect(find.text('45'), findsOneWidget);
    expect(find.text('minutos'), findsOneWidget);

    await accept(tester);

    expect(result.minutes, 45);
  });

  testWidgets('un margen de horas abre la rueda en horas', (tester) async {
    final result = await open(tester, initialMinutes: 120);

    expect(find.text('2'), findsOneWidget);
    expect(find.text('horas'), findsOneWidget);

    await accept(tester);

    expect(result.minutes, 120);
  });

  testWidgets('un margen de días abre la rueda en días', (tester) async {
    final result = await open(tester, initialMinutes: 4320);

    expect(find.text('3'), findsOneWidget);
    expect(find.text('días'), findsOneWidget);

    await accept(tester);

    expect(result.minutes, 4320);
  });

  testWidgets('el margen de 10 minutos sigue abriendo en 10', (tester) async {
    final result = await open(tester, initialMinutes: 10);

    expect(find.text('10'), findsOneWidget);

    await accept(tester);

    expect(result.minutes, 10);
  });

  testWidgets('un margen que no cae en la rueda se lleva a la más cercana', (
    tester,
  ) async {
    // Los minutos van de 5 en 5, así que 7 no existe: se abre en 5.
    final result = await open(tester, initialMinutes: 7);

    expect(find.text('5'), findsOneWidget);

    await accept(tester);

    expect(result.minutes, 5);
  });

  testWidgets('cambiar de unidad dice el mismo margen en la unidad nueva', (
    tester,
  ) async {
    final result = await open(tester, initialMinutes: 45);

    // La segunda rueda es la de unidad: un paso hacia arriba la deja en horas.
    await tester.drag(
      find.byType(ListWheelScrollView).last,
      const Offset(0, -WheelPicker.itemExtent),
    );
    await tester.pumpAndSettle();

    // 45 minutos no son 0,75 horas: la cantidad más cercana son 1 hora.
    expect(find.text('1'), findsOneWidget);
    expect(find.text('horas'), findsOneWidget);

    await accept(tester);

    expect(result.minutes, 60);
  });

  testWidgets('cerrarlo sin aceptar no devuelve nada', (tester) async {
    final result = await open(tester, initialMinutes: 45);

    // Fuera del sheet: se cierra descartándolo.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(result.opened, isTrue);
    expect(result.minutes, isNull);
  });
}
