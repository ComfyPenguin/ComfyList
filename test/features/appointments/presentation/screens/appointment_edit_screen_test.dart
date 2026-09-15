import 'package:comfy_list/features/appointments/presentation/providers/appointments_provider.dart';
import 'package:comfy_list/features/appointments/presentation/providers/appointments_state.dart';
import 'package:comfy_list/features/appointments/presentation/screens/appointment_edit_screen.dart';
import 'package:comfy_list/features/settings/presentation/providers/settings_provider.dart';
import 'package:comfy_list/shared/core/theme/app_theme.dart';
import 'package:comfy_list/shared/data/notifications/notifications_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../../../helpers/fake_notifications_service.dart';
import '../../../../helpers/fake_settings_repository.dart';
import '../../../../helpers/test_helpers.dart';

/// Notifier de citas con la lista vacía: la pantalla solo la mira para hidratar
/// una cita existente, y aquí se crea una nueva.
class _EmptyAppointmentsNotifier extends AppointmentsNotifier {
  @override
  AppointmentsState build() => AppointmentsData(const []);
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
  }) async {
    // El formulario entero tiene que caber: si no, el aviso queda fuera de la
    // ventana y la lista ni lo construye.
    tester.view.physicalSize = const Size(1170, 4200);
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
}
