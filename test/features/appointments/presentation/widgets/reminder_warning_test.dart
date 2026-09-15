import 'package:comfy_list/features/appointments/presentation/widgets/reminder_warning.dart';
import 'package:comfy_list/features/settings/presentation/providers/settings_provider.dart';
import 'package:comfy_list/shared/core/theme/app_theme.dart';
import 'package:comfy_list/shared/data/notifications/notifications_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fake_notifications_service.dart';
import '../../../../helpers/fake_settings_repository.dart';
import '../../../../helpers/test_helpers.dart';

void main() {
  Future<void> pumpWarning(
    WidgetTester tester, {
    required bool notificationsEnabled,
    bool systemAllows = true,
  }) async {
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
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: ReminderWarning()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pumpAndSettle();
  }

  testWidgets('con los avisos apagados dice que no sonará', (tester) async {
    await pumpWarning(tester, notificationsEnabled: false);

    expect(find.textContaining('Avisos apagados'), findsOneWidget);
  });

  testWidgets('con el sistema bloqueándolos dice que no sonará', (
    tester,
  ) async {
    await pumpWarning(tester, notificationsEnabled: true, systemAllows: false);

    expect(find.textContaining('El sistema bloquea'), findsOneWidget);
  });

  testWidgets('si los apagó el usuario, no culpa al sistema', (tester) async {
    await pumpWarning(tester, notificationsEnabled: false, systemAllows: false);

    expect(find.textContaining('Avisos apagados'), findsOneWidget);
    expect(find.textContaining('El sistema bloquea'), findsNothing);
  });

  testWidgets('con los avisos funcionando no dice nada', (tester) async {
    await pumpWarning(tester, notificationsEnabled: true);

    expect(find.textContaining('recordatorio'), findsNothing);
  });
}
