import 'package:comfy_list/features/appointments/domain/entities/appointment.dart';
import 'package:comfy_list/features/appointments/presentation/providers/appointments_provider.dart';
import 'package:comfy_list/features/appointments/presentation/providers/appointments_state.dart';
import 'package:comfy_list/features/appointments/presentation/screens/appointments_screen.dart';
import 'package:comfy_list/features/settings/presentation/providers/settings_provider.dart';
import 'package:comfy_list/shared/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import '../../../../helpers/fake_settings_repository.dart';
import '../../../../helpers/test_helpers.dart';

/// Notifier de citas con una lista fija: sin repo ni auth de por medio.
class _FixedAppointmentsNotifier extends AppointmentsNotifier {
  _FixedAppointmentsNotifier(this.items);

  final List<Appointment> items;

  @override
  AppointmentsState build() => AppointmentsData(items);
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // Las cabeceras de fecha van en es_ES y la app lo inicializa en main().
    await initializeDateFormatting('es_ES');
    final loader = FontLoader('PlusJakartaSans')
      ..addFont(
        rootBundle.load('assets/fonts/PlusJakartaSans-VariableFont.ttf'),
      );
    await loader.load();
  });

  // Fecha fija: la pantalla la recibe inyectada, así que el test no depende
  // del reloj de la máquina.
  final today = DateTime(2026, 9, 15, 10);
  final yesterday = DateTime(2026, 9, 14, 9);

  // Misma cabecera que pinta la pantalla para el día de ayer.
  String headerOf(DateTime date) =>
      DateFormat('EEEE, d MMM', 'es_ES').format(date).toUpperCase();

  Future<void> pumpScreen(
    WidgetTester tester, {
    required bool todayOnTop,
  }) async {
    final repo = FakeSettingsRepository(
      settings: buildAppSettings(appointmentsTodayOnTop: todayOnTop),
    );
    addTearDown(repo.close);

    tester.view.physicalSize = const Size(1170, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appointmentsProvider.overrideWith(
            () => _FixedAppointmentsNotifier([
              buildAppointment(id: 'ayer', title: 'Ayer', dateTime: yesterday),
              buildAppointment(id: 'hoy', title: 'Hoy', dateTime: today),
            ]),
          ),
          settingsRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: AppointmentsScreen(today: today),
        ),
      ),
    );
    // La píldora de hoy late sin parar: `pumpAndSettle` no vuelve nunca.
    await tester.pump();
    await tester.pump();
    await tester.pump();
  }

  testWidgets('con «Citas de hoy arriba», el día de hoy encabeza la lista', (
    tester,
  ) async {
    await pumpScreen(tester, todayOnTop: true);

    expect(
      tester.getTopLeft(find.text('CITAS DE HOY')).dy,
      lessThan(tester.getTopLeft(find.text(headerOf(yesterday))).dy),
    );
  });

  testWidgets('con el ajuste apagado manda el orden por fecha', (tester) async {
    await pumpScreen(tester, todayOnTop: false);

    expect(
      tester.getTopLeft(find.text(headerOf(yesterday))).dy,
      lessThan(tester.getTopLeft(find.text('CITAS DE HOY')).dy),
    );
  });
}
