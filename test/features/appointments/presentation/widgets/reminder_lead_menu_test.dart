import 'package:comfy_list/features/appointments/presentation/widgets/reminder_lead_menu.dart';
import 'package:comfy_list/shared/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Lo que devolvió el menú, que llega cuando el sheet se cierra.
class _Result {
  ReminderLeadOption? option;

  int get minutes => (option! as PresetReminderLead).minutes;
}

/// Pantalla mínima con un botón que abre el menú que le pidan.
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
  /// Abre el menú y deja el test delante del sheet.
  Future<_Result> openMenu(
    WidgetTester tester, {
    required List<int> taken,
  }) async {
    final result = _Result();
    await tester.pumpWidget(
      _Host(
        onOpen: (context) async {
          result.option = await showReminderLeadMenu(context, taken: taken);
        },
      ),
    );

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    return result;
  }

  testWidgets('ofrece los tiempos que la cita no tiene puestos', (
    tester,
  ) async {
    await openMenu(tester, taken: const [5, 60]);

    for (final label in [
      '10 minutos antes',
      '15 minutos antes',
      '30 minutos antes',
      '1 día antes',
      'Personalizada',
    ]) {
      expect(find.text(label), findsOneWidget, reason: 'falta $label');
    }
    expect(find.text('5 minutos antes'), findsNothing);
    expect(find.text('1 hora antes'), findsNothing);
  });

  testWidgets('elegir un tiempo devuelve su margen', (tester) async {
    final result = await openMenu(tester, taken: const []);

    await tester.tap(find.text('30 minutos antes'));
    await tester.pumpAndSettle();

    expect(result.option, isA<PresetReminderLead>());
    expect(result.minutes, 30);
  });

  testWidgets('elegir la personalizada pide la cantidad', (tester) async {
    final result = await openMenu(tester, taken: const [30]);

    await tester.tap(find.text('Personalizada'));
    await tester.pumpAndSettle();

    expect(result.option, isA<CustomReminderLead>());
  });

  testWidgets('un personalizado puesto no quita que se pida otro', (
    tester,
  ) async {
    final result = await openMenu(tester, taken: const [30, 45]);

    expect(find.text('Personalizada'), findsOneWidget);

    await tester.tap(find.text('Personalizada'));
    await tester.pumpAndSettle();

    expect(result.option, isA<CustomReminderLead>());
  });

  testWidgets('con los cinco puestos no queda nada que ofrecer', (
    tester,
  ) async {
    await openMenu(tester, taken: const [5, 10, 15, 30, 45]);

    expect(find.text('Personalizada'), findsNothing);
    expect(find.textContaining('antes'), findsNothing);
  });

  testWidgets('cerrarlo sin elegir no devuelve nada', (tester) async {
    final result = await openMenu(tester, taken: const []);

    // Fuera del sheet: se cierra descartándolo.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(result.option, isNull);
  });
}
