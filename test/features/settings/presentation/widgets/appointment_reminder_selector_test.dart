import 'package:comfy_list/features/settings/presentation/providers/settings_provider.dart';
import 'package:comfy_list/features/settings/presentation/widgets/appointment_reminder_selector.dart';
import 'package:comfy_list/shared/core/theme/app_theme.dart';
import 'package:comfy_list/shared/ui/inputs/app_filter_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fake_settings_repository.dart';
import '../../../../helpers/test_helpers.dart';

void main() {
  /// Monta el selector con los márgenes guardados que se le pasen.
  Future<void> pumpSelector(WidgetTester tester, {List<int>? minutes}) async {
    final repo = FakeSettingsRepository(
      settings: buildAppSettings(appointmentReminderMinutes: minutes),
    );
    addTearDown(repo.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [settingsRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: Center(
              child: SizedBox(width: 390, child: AppointmentReminderSelector()),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  AppFilterChip chip(WidgetTester tester, String label) =>
      tester.widget<AppFilterChip>(find.widgetWithText(AppFilterChip, label));

  /// Etiquetas de los chips encendidos, en el orden en que salen en la fila.
  List<String> selected(WidgetTester tester) => tester
      .widgetList<AppFilterChip>(find.byType(AppFilterChip))
      .where((chip) => chip.selected)
      .map((chip) => chip.label)
      .toList();

  testWidgets('ofrece los presets y el personalizado, sin el de a la hora', (
    tester,
  ) async {
    await pumpSelector(tester);

    for (final label in ['5 min', '10 min', '30 min', '1 h', '1 día']) {
      expect(find.text(label), findsOneWidget, reason: 'falta $label');
    }
    expect(find.text('A la hora'), findsNothing);
    expect(find.text('Personalizado'), findsOneWidget);
  });

  testWidgets('los márgenes guardados van encendidos', (tester) async {
    await pumpSelector(tester, minutes: const [5, 60]);

    expect(selected(tester), ['5 min', '1 h']);
  });

  testWidgets('tocar un preset lo añade y volver a tocarlo lo quita', (
    tester,
  ) async {
    await pumpSelector(tester);

    await tester.tap(find.text('1 h'));
    await tester.pumpAndSettle();

    expect(selected(tester), ['30 min', '1 h']);

    await tester.tap(find.text('1 h'));
    await tester.pumpAndSettle();

    expect(selected(tester), ['30 min']);
  });

  testWidgets('con tres puestos los que sobran dejan de responder', (
    tester,
  ) async {
    await pumpSelector(tester, minutes: const [5, 30, 60]);

    expect(chip(tester, '1 día').onTap, isNull);
    expect(chip(tester, 'Personalizado').onTap, isNull);
    // Los que ya están puestos se pueden quitar —es la forma de hacer hueco—.
    expect(chip(tester, '30 min').onTap, isNotNull);
    expect(find.textContaining('Máximo 3 recordatorios'), findsOneWidget);
  });

  testWidgets('con dos puestos todavía cabe uno más', (tester) async {
    await pumpSelector(tester, minutes: const [5, 30]);

    expect(chip(tester, '1 día').onTap, isNotNull);
    expect(chip(tester, 'Personalizado').onTap, isNotNull);
    expect(find.textContaining('Máximo 3'), findsNothing);
  });

  testWidgets('el personalizado se elige en su selector y queda como chip', (
    tester,
  ) async {
    await pumpSelector(tester);

    await tester.tap(find.text('Personalizado'));
    await tester.pumpAndSettle();

    // Se abre en los 15 minutos de partida.
    await tester.tap(find.text('ACEPTAR'));
    await tester.pumpAndSettle();

    expect(selected(tester), ['30 min', 'Personalizado: 15 min']);
    expect(find.text('Personalizado'), findsNothing);
  });

  testWidgets('el personalizado se quita desde su selector', (tester) async {
    await pumpSelector(tester, minutes: const [30, 45]);

    await tester.tap(find.text('Personalizado: 45 min'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quitar'));
    await tester.pumpAndSettle();

    expect(selected(tester), ['30 min']);
    expect(find.text('Personalizado'), findsOneWidget);
  });

  testWidgets('un margen que no es preset sale como personalizado', (
    tester,
  ) async {
    await pumpSelector(tester, minutes: const [90]);

    expect(selected(tester), ['Personalizado: 90 min']);
    expect(find.text('Personalizado'), findsNothing);
  });

  testWidgets('el aviso a la hora que quedara guardado sigue leyéndose', (
    tester,
  ) async {
    // Ya no se ofrece, pero quien lo tuviera puesto no lo ve como «0 min».
    await pumpSelector(tester, minutes: const [0]);

    expect(selected(tester), ['Personalizado: A la hora']);
  });

  group('formatReminderLead', () {
    test('lee los presets como los ofrece Ajustes', () {
      expect(formatReminderLead(5), '5 min');
      expect(formatReminderLead(10), '10 min');
      expect(formatReminderLead(30), '30 min');
      expect(formatReminderLead(60), '1 h');
      expect(formatReminderLead(1440), '1 día');
    });

    test('cuenta días y horas en plural', () {
      expect(formatReminderLead(120), '2 h');
      expect(formatReminderLead(2880), '2 días');
    });

    test('los minutos que no llenan una hora van en minutos', () {
      expect(formatReminderLead(20), '20 min');
      expect(formatReminderLead(90), '90 min');
    });

    test('el cero es el aviso a la hora de la cita, de antes', () {
      expect(formatReminderLead(0), 'A la hora');
    });
  });
}
