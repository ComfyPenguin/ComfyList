import 'package:comfy_list/features/appointments/domain/entities/appointment.dart';
import 'package:comfy_list/features/appointments/presentation/widgets/appointment_tile.dart';
import 'package:comfy_list/features/settings/presentation/providers/settings_provider.dart';
import 'package:comfy_list/features/settings/presentation/providers/settings_state.dart';
import 'package:comfy_list/shared/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Los ajustes siguen cargando: nunca llega el `SettingsData`.
class _LoadingSettings extends SettingsNotifier {
  @override
  SettingsState build() => const SettingsLoading();
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es_ES');
  });

  // Hora local de la tarde: en 12 h se ve «03:30 PM» y en 24 h «15:30».
  final appointment = Appointment(
    id: 'a1',
    title: 'Dentista',
    dateTime: DateTime(2026, 6, 1, 15, 30),
    isDone: false,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );

  testWidgets('mientras cargan los ajustes pinta la hora en el formato de fábrica',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsProvider.overrideWith(_LoadingSettings.new),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: AppointmentTile(
              appointment: appointment,
              onTap: () {},
              onComplete: () {},
              onDelete: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('15:30'), findsOneWidget);
    expect(find.text('PM'), findsNothing);
  });
}
