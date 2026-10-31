import 'dart:async';

import 'package:comfy_list/features/appointments/domain/entities/appointment.dart';
import 'package:comfy_list/features/appointments/domain/entities/repeat_rule.dart';
import 'package:comfy_list/features/appointments/presentation/providers/appointments_provider.dart';
import 'package:comfy_list/features/appointments/presentation/providers/appointments_state.dart';
import 'package:comfy_list/features/appointments/presentation/screens/appointment_edit_screen.dart';
import 'package:comfy_list/features/settings/presentation/providers/settings_provider.dart';
import 'package:comfy_list/shared/core/theme/app_theme.dart';
import 'package:comfy_list/shared/data/notifications/notifications_provider.dart';
import 'package:comfy_list/shared/ui/inputs/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../../../helpers/fake_notifications_service.dart';
import '../../../../helpers/fake_settings_repository.dart';
import '../../../../helpers/test_helpers.dart';
import '../../../../helpers/test_router.dart';

/// Notifier de citas con la lista vacía: la pantalla solo la mira para hidratar
/// una cita existente, y aquí se crea una nueva.
class _EmptyAppointmentsNotifier extends AppointmentsNotifier {
  @override
  AppointmentsState build() => AppointmentsData(const []);
}

/// Notifier de citas que apunta lo que la pantalla le pide guardar, para
/// comprobar la regla sin pasar por repositorio ni red.
class _RecordingAppointmentsNotifier extends AppointmentsNotifier {
  _RecordingAppointmentsNotifier([this.items = const []]);

  final List<Appointment> items;
  ({RepeatRule? repeatRule})? created;
  ({RepeatRule? repeatRule, bool clearRepeatRule})? updated;

  @override
  AppointmentsState build() => AppointmentsData(items);

  @override
  Future<bool> create({
    required String title,
    String? description,
    String? location,
    RepeatRule? repeatRule,
    required DateTime dateTime,
  }) async {
    created = (repeatRule: repeatRule);
    return true;
  }

  @override
  Future<bool> updateFields({
    required String id,
    String? title,
    String? description,
    bool clearDescription = false,
    String? location,
    bool clearLocation = false,
    RepeatRule? repeatRule,
    bool clearRepeatRule = false,
    DateTime? dateTime,
  }) async {
    updated = (repeatRule: repeatRule, clearRepeatRule: clearRepeatRule);
    return true;
  }
}

void main() {
  setUpAll(() async {
    // La pantalla formatea la fecha en es_ES, como el resto de la app.
    await initializeDateFormatting('es_ES');
  });

  Future<void> pumpEditScreen(
    WidgetTester tester, {
    required bool notificationsEnabled,
    bool systemAllows = true,
    Size physicalSize = const Size(1170, 4200),
  }) async {
    // El formulario entero tiene que caber: si no, el aviso queda fuera de la
    // ventana y la lista ni lo construye.
    tester.view.physicalSize = physicalSize;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final repo = FakeSettingsRepository(
      settings: buildAppSettings(notificationsEnabled: notificationsEnabled),
    );
    addTearDown(repo.close);
    final notifications = FakeNotificationsService()
      ..notificationsAllowed = systemAllows;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(repo),
          notificationsServiceProvider.overrideWithValue(notifications),
          appointmentsProvider.overrideWith(_EmptyAppointmentsNotifier.new),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const AppointmentEditScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pumpAndSettle();
  }

  testWidgets('avisa de que el recordatorio no sonará', (tester) async {
    await pumpEditScreen(tester, notificationsEnabled: false);

    expect(find.textContaining('Avisos apagados'), findsOneWidget);
  });

  testWidgets('con los avisos funcionando no avisa de nada', (tester) async {
    await pumpEditScreen(tester, notificationsEnabled: true);

    expect(find.textContaining('recordatorio'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  group('repetición', () {
    /// Abre la pantalla de crear (`id` nulo) o de editar encima de una ruta
    /// de inicio, para que guardar tenga a dónde volver.
    Future<void> pumpRouted(
      WidgetTester tester,
      _RecordingAppointmentsNotifier notifier, {
      String? id,
    }) async {
      tester.view.physicalSize = const Size(1170, 4200);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      final settings = FakeSettingsRepository(
        settings: buildAppSettings(notificationsEnabled: true),
      );
      addTearDown(settings.close);
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const RouteProbe(label: 'inicio'),
          ),
          GoRoute(
            path: '/edit',
            builder: (_, _) => AppointmentEditScreen(id: id),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsRepositoryProvider.overrideWithValue(settings),
            notificationsServiceProvider.overrideWithValue(
              FakeNotificationsService(),
            ),
            appointmentsProvider.overrideWith(() => notifier),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light(),
            routerConfig: router,
          ),
        ),
      );
      unawaited(router.push('/edit'));
      await tester.pumpAndSettle();
    }

    final clearButton = find.byTooltip('Quitar repetición');

    testWidgets('una cita nueva no se repite y no ofrece quitar nada', (
      tester,
    ) async {
      await pumpRouted(tester, _RecordingAppointmentsNotifier());

      expect(find.text('No se repite'), findsOneWidget);
      expect(clearButton, findsNothing);
    });

    testWidgets('elegir una regla la muestra y se guarda con la cita', (
      tester,
    ) async {
      final notifier = _RecordingAppointmentsNotifier();
      await pumpRouted(tester, notifier);
      await tester.enterText(find.byType(EditableText).first, 'Pagar alquiler');

      await tester.tap(find.text('No se repite'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ACEPTAR'));
      await tester.pumpAndSettle();

      expect(find.text('Cada día'), findsOneWidget);
      expect(clearButton, findsOneWidget);

      await tester.tap(find.text('CREAR'));
      await tester.pumpAndSettle();

      expect(
        notifier.created?.repeatRule,
        const RepeatRule(interval: 1, unit: RepeatUnit.day),
      );
      expect(find.text('inicio'), findsOneWidget);
    });

    testWidgets('una cita recurrente se abre con su regla', (tester) async {
      await pumpRouted(
        tester,
        _RecordingAppointmentsNotifier([
          buildAppointment(
            id: 'a1',
            repeatRule: const RepeatRule(interval: 2, unit: RepeatUnit.week),
          ),
        ]),
        id: 'a1',
      );

      expect(find.text('Cada 2 semanas'), findsOneWidget);
    });

    testWidgets('quitar la regla se guarda como una cita que no se repite', (
      tester,
    ) async {
      final notifier = _RecordingAppointmentsNotifier([
        buildAppointment(
          id: 'a1',
          repeatRule: const RepeatRule(interval: 2, unit: RepeatUnit.week),
        ),
      ]);
      await pumpRouted(tester, notifier, id: 'a1');

      await tester.tap(clearButton);
      await tester.pumpAndSettle();
      expect(find.text('No se repite'), findsOneWidget);

      await tester.tap(find.text('GUARDAR'));
      await tester.pumpAndSettle();

      expect(notifier.updated?.repeatRule, isNull);
      expect(notifier.updated?.clearRepeatRule, isTrue);
    });

    testWidgets('guardar sin tocar la regla la conserva', (tester) async {
      final notifier = _RecordingAppointmentsNotifier([
        buildAppointment(
          id: 'a1',
          repeatRule: const RepeatRule(interval: 2, unit: RepeatUnit.week),
        ),
      ]);
      await pumpRouted(tester, notifier, id: 'a1');

      await tester.tap(find.text('GUARDAR'));
      await tester.pumpAndSettle();

      expect(
        notifier.updated?.repeatRule,
        const RepeatRule(interval: 2, unit: RepeatUnit.week),
      );
      expect(notifier.updated?.clearRepeatRule, isFalse);
    });
  });

  testWidgets('en un móvil estrecho no desborda', (tester) async {
    await pumpEditScreen(
      tester,
      notificationsEnabled: true,
      // 320 de ancho, con el alto de siempre para que el formulario entero
      // entre en la ventana.
      physicalSize: const Size(960, 4200),
    );

    // Un desborde llega aquí como excepción: no haberla es la comprobación.
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(AppTextField).first).width, 288);
  });
}
