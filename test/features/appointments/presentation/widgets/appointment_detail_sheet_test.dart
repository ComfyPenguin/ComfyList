import 'package:comfy_list/features/appointments/presentation/providers/appointments_provider.dart';
import 'package:comfy_list/features/appointments/presentation/providers/appointments_state.dart';
import 'package:comfy_list/features/appointments/presentation/widgets/appointment_detail_sheet.dart';
import 'package:comfy_list/features/settings/presentation/providers/settings_provider.dart';
import 'package:comfy_list/shared/core/failures/failure.dart';
import 'package:comfy_list/shared/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fake_settings_repository.dart';

class _FixedAppointments extends AppointmentsNotifier {
  _FixedAppointments(this._state);

  final AppointmentsState _state;

  @override
  AppointmentsState build() => _state;
}

void main() {
  /// Tope que el sheet se pone a sí mismo: el 85 % de la pantalla del test.
  const cap = 600 * 0.85;

  Future<void> pumpSheet(WidgetTester tester, AppointmentsState state) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appointmentsProvider.overrideWith(() => _FixedAppointments(state)),
          settingsRepositoryProvider.overrideWithValue(
            FakeSettingsRepository(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: AppointmentDetailSheet(id: 'a1', onEdit: () {}),
          ),
        ),
      ),
    );
  }

  double sheetHeight(WidgetTester tester) =>
      tester.getSize(find.byType(AppointmentDetailSheet)).height;

  testWidgets('cargando mide lo que el spinner', (tester) async {
    await pumpSheet(tester, const AppointmentsLoading());

    expect(sheetHeight(tester), lessThan(cap));
  });

  testWidgets('el error mide lo que el mensaje', (tester) async {
    await pumpSheet(
      tester,
      const AppointmentsError(UnknownFailure('No se pudieron cargar.')),
    );

    expect(sheetHeight(tester), lessThan(cap));
  });

  testWidgets('la cita eliminada mide lo que el mensaje', (tester) async {
    await pumpSheet(tester, const AppointmentsData([]));

    expect(sheetHeight(tester), lessThan(cap));
  });
}
