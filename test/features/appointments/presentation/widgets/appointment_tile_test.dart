import 'package:comfy_list/features/appointments/domain/entities/appointment.dart';
import 'package:comfy_list/features/appointments/domain/entities/repeat_rule.dart';
import 'package:comfy_list/features/appointments/presentation/widgets/appointment_tile.dart';
import 'package:comfy_list/features/settings/presentation/providers/settings_provider.dart';
import 'package:comfy_list/features/settings/presentation/providers/settings_state.dart';
import 'package:comfy_list/shared/core/theme/app_theme.dart';
import 'package:comfy_list/shared/ui/text/animated_strikethrough_text.dart';
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

  testWidgets('deslizar hacia la derecha completa la cita sin ningún ajuste',
      (tester) async {
    var completed = 0;
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
              onComplete: () => completed++,
              onDelete: () {},
            ),
          ),
        ),
      ),
    );

    await tester.fling(
      find.byType(AppointmentTile),
      const Offset(500, 0),
      1000,
    );
    await tester.pumpAndSettle();

    expect(completed, 1);
  });

  testWidgets('una cita recurrente lleva el icono de repetición', (
    tester,
  ) async {
    Future<void> pumpTile(Appointment shown) => tester.pumpWidget(
      ProviderScope(
        overrides: [settingsProvider.overrideWith(_LoadingSettings.new)],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: AppointmentTile(
              appointment: shown,
              onTap: () {},
              onComplete: () {},
              onDelete: () {},
            ),
          ),
        ),
      ),
    );

    await pumpTile(appointment);
    expect(find.byIcon(Icons.repeat_rounded), findsNothing);

    await pumpTile(
      appointment.copyWith(
        repeatRule: const RepeatRule(interval: 1, unit: RepeatUnit.week),
      ),
    );
    expect(find.byIcon(Icons.repeat_rounded), findsOneWidget);
  });

  testWidgets('una cita completada se ve tachada', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsProvider.overrideWith(_LoadingSettings.new),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: AppointmentTile(
              appointment: appointment.copyWith(isDone: true),
              onTap: () {},
              onComplete: () {},
              onDelete: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final title = tester.widget<AnimatedStrikethroughText>(
      find.byType(AnimatedStrikethroughText),
    );
    expect(title.done, isTrue);
  });
}
