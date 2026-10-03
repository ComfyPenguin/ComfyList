import 'package:comfy_list/shared/core/theme/app_theme.dart';
import 'package:comfy_list/shared/core/time/clock.dart';
import 'package:comfy_list/shared/ui/pickers/date_time_pickers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Pantalla mínima con un botón que abre el picker que le pasen, con el reloj
/// de la app fijado en [now].
class _Host extends StatelessWidget {
  const _Host({required this.onOpen, required this.now});

  final void Function(BuildContext context) onOpen;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [clockProvider.overrideWithValue(() => now)],
      child: MaterialApp(
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
      ),
    );
  }
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // Meses, días de la semana y AM/PM van en es_ES: la app lo inicializa en
    // main().
    await initializeDateFormatting('es_ES');
    final loader = FontLoader('PlusJakartaSans')
      ..addFont(
        rootBundle.load('assets/fonts/PlusJakartaSans-VariableFont.ttf'),
      );
    await loader.load();
  });

  /// Borde del círculo del día [day] del calendario: lo lleva el día de hoy
  /// cuando no está seleccionado.
  BorderSide dayBorder(WidgetTester tester, String day) {
    final material = tester.widget<Material>(
      find.ancestor(of: find.text(day), matching: find.byType(Material)).first,
    );
    return (material.shape! as CircleBorder).side;
  }

  testWidgets('el calendario marca el día del reloj como hoy', (tester) async {
    // El día del reloj no coincide con el que elige el calendario al abrir, que
    // es el único que lleva el relleno primario.
    final now = DateTime(2026, 3, 10, 18);

    DateTime? picked;
    await tester.pumpWidget(
      _Host(
        now: now,
        onOpen: (context) async {
          picked = await showAppDatePicker(
            context,
            initialDate: DateTime(2026, 3, 20),
          );
        },
      ),
    );

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Marzo de 2026'), findsOneWidget);
    expect(dayBorder(tester, '10'), isNot(BorderSide.none));
    expect(dayBorder(tester, '11'), BorderSide.none);

    await tester.tap(find.text('20'));
    await tester.pump();
    await tester.tap(find.text('ACEPTAR'));
    await tester.pumpAndSettle();

    expect(picked, DateTime(2026, 3, 20));
  });

  testWidgets('el selector de hora devuelve la hora elegida en 24 h', (
    tester,
  ) async {
    TimeOfDay? picked;
    await tester.pumpWidget(
      _Host(
        now: DateTime(2026, 3, 10, 18),
        onOpen: (context) async {
          picked = await showAppTimePicker(
            context,
            initialTime: const TimeOfDay(hour: 14, minute: 30),
          );
        },
      ),
    );

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.text('14'), findsOneWidget);
    expect(find.text('30'), findsOneWidget);
    expect(find.text('PM'), findsNothing);

    await tester.tap(find.text('ACEPTAR'));
    await tester.pumpAndSettle();

    expect(picked, const TimeOfDay(hour: 14, minute: 30));
  });

  testWidgets('en 12 h la rueda de horas va de 1 a 12 con AM/PM', (
    tester,
  ) async {
    TimeOfDay? picked;
    await tester.pumpWidget(
      _Host(
        now: DateTime(2026, 3, 10, 18),
        onOpen: (context) async {
          picked = await showAppTimePicker(
            context,
            initialTime: const TimeOfDay(hour: 14, minute: 30),
            use24HourFormat: false,
          );
        },
      ),
    );

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.text('2'), findsOneWidget);
    expect(find.text('PM'), findsOneWidget);

    await tester.tap(find.text('ACEPTAR'));
    await tester.pumpAndSettle();

    // Las 2 de la tarde vuelven como 14:30.
    expect(picked, const TimeOfDay(hour: 14, minute: 30));
  });
}
