import 'package:comfy_list/features/appointments/presentation/widgets/appointment_reminder_selector.dart';
import 'package:comfy_list/shared/core/theme/app_theme.dart';
import 'package:comfy_list/shared/ui/buttons/primary_button.dart';
import 'package:comfy_list/shared/ui/inputs/app_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';


void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // Con la fuente de verdad las pastillas miden lo que miden de verdad: las
    // etiquetas largas son las que aprietan la fila.
    final loader = FontLoader('PlusJakartaSans')
      ..addFont(
        rootBundle.load('assets/fonts/PlusJakartaSans-VariableFont.ttf'),
      );
    await loader.load();
  });

  /// Lo último que el selector pidió guardar: quien lo monta es el dueño de la
  /// lista, y aquí hace de la pantalla que la guarda.
  late List<int> current;

  /// Monta el selector con los recordatorios que se le pasen.
  Future<void> pumpSelector(
    WidgetTester tester, {
    required List<int> minutes,
  }) async {
    current = minutes;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 390,
              child: StatefulBuilder(
                builder: (context, setState) => AppointmentReminderSelector(
                  selected: current,
                  onChanged: (next) => setState(() => current = next),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Etiquetas de las pastillas puestas, en el orden en que salen.
  List<String> chips(WidgetTester tester) => tester
      .widgetList<AppChip>(find.byType(AppChip))
      .map((chip) => chip.label)
      .toList();

  Future<void> openMenu(WidgetTester tester) async {
    await tester.tap(find.text('AÑADIR RECORDATORIO'));
    await tester.pumpAndSettle();
  }

  testWidgets('los recordatorios guardados salen como pastillas', (
    tester,
  ) async {
    await pumpSelector(tester, minutes: const [5, 45]);

    expect(chips(tester), ['5 min', '45 min']);
    // Centradas en la fila, no pegadas a la izquierda.
    expect(
      tester.widget<Wrap>(find.byType(Wrap)).alignment,
      WrapAlignment.center,
    );
  });

  testWidgets('sin recordatorios solo está el botón de añadir', (tester) async {
    await pumpSelector(tester, minutes: const []);

    expect(chips(tester), isEmpty);
    expect(find.text('AÑADIR RECORDATORIO'), findsOneWidget);
  });

  testWidgets('el botón abre el menú con los tiempos', (tester) async {
    await pumpSelector(tester, minutes: const [5]);

    await openMenu(tester);

    for (final label in [
      '10 minutos antes',
      '15 minutos antes',
      '30 minutos antes',
      '1 hora antes',
      '1 día antes',
      'Personalizada',
    ]) {
      expect(find.text(label), findsOneWidget, reason: 'falta $label');
    }
    // El que ya está puesto no se puede repetir.
    expect(find.text('5 minutos antes'), findsNothing);
  });

  testWidgets('elegir un tiempo añade su pastilla', (tester) async {
    await pumpSelector(tester, minutes: const [30]);

    await openMenu(tester);
    await tester.tap(find.text('15 minutos antes'));
    await tester.pumpAndSettle();

    expect(chips(tester), ['15 min', '30 min']);
    expect(current, [15, 30]);
  });

  testWidgets('«A su hora» se elige desde el menú y sale la primera', (
    tester,
  ) async {
    await pumpSelector(tester, minutes: const [30]);

    await openMenu(tester);
    await tester.tap(find.text('A su hora'));
    await tester.pumpAndSettle();

    expect(chips(tester), ['A la hora', '30 min']);
    expect(current, [0, 30]);
  });

  testWidgets('el personalizado se elige desde el menú', (tester) async {
    await pumpSelector(tester, minutes: const [30]);

    await openMenu(tester);
    await tester.tap(find.text('Personalizada'));
    await tester.pumpAndSettle();

    // Se abre en los 20 minutos de partida.
    await tester.tap(find.text('ACEPTAR'));
    await tester.pumpAndSettle();

    // Los márgenes van de menor a mayor, y el personalizado es uno más.
    expect(chips(tester), ['20 min', '30 min']);
  });

  testWidgets('los personalizados se acumulan, cada uno por su cuenta', (
    tester,
  ) async {
    await pumpSelector(tester, minutes: const [30, 45]);

    await openMenu(tester);
    // La rueda es para el margen nuevo, no para el que ya está puesto.
    await tester.tap(find.text('Personalizada'));
    await tester.pumpAndSettle();

    // La primera rueda es la de cantidad: un paso abajo deja 15 minutos.
    await tester.drag(
      find.byType(ListWheelScrollView).first,
      const Offset(0, 44),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('ACEPTAR'));
    await tester.pumpAndSettle();

    expect(chips(tester), ['15 min', '30 min', '45 min']);
  });

  testWidgets('quitar una pastilla la saca de la cita', (tester) async {
    await pumpSelector(tester, minutes: const [30, 45]);

    await tester.tap(find.text('30 min'));
    await tester.pumpAndSettle();

    expect(chips(tester), ['45 min']);
    expect(current, [45]);
  });

  testWidgets('con los cinco puestos el botón se va y no deja hueco', (
    tester,
  ) async {
    // Aunque uno de los cinco sea personalizado: el tope lo cuentan todos.
    await pumpSelector(tester, minutes: const [5, 10, 15, 30, 45]);
    await tester.pumpAndSettle();

    // El botón sigue montado —es lo que le permite volver con su fundido—, así
    // que lo que se mira es que no ocupe alto y que no responda.
    final block = find.ancestor(
      of: find.byType(PrimaryButton),
      matching: find.byType(AnimatedAlign),
    );
    expect(tester.getSize(block).height, 0);

    await tester.tap(find.byType(PrimaryButton), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('10 minutos antes'), findsNothing);

    // Y al quitar una pastilla vuelve abriendo el hueco, no de golpe.
    await tester.tap(find.text('45 min'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final midway = tester.getSize(block).height;

    await tester.pumpAndSettle();
    final expanded = tester.getSize(block).height;

    expect(midway, greaterThan(0));
    expect(midway, lessThan(expanded));
  });

  testWidgets('un aviso a la hora se lee «A la hora»', (
    tester,
  ) async {
    await pumpSelector(tester, minutes: const [0]);

    expect(chips(tester), ['A la hora']);
  });
}
