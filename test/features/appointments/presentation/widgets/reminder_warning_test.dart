import 'package:comfy_list/features/appointments/presentation/widgets/reminder_warning.dart';
import 'package:comfy_list/features/settings/presentation/providers/settings_provider.dart';
import 'package:comfy_list/routing/routes.dart';
import 'package:comfy_list/shared/core/theme/app_theme.dart';
import 'package:comfy_list/shared/data/notifications/notifications_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../../helpers/fake_notifications_service.dart';
import '../../../../helpers/fake_settings_repository.dart';
import '../../../../helpers/test_helpers.dart';

void main() {
  /// Monta el aviso con una ruta de Ajustes de mentira, para poder comprobar a
  /// dónde lleva el toque.
  Future<FakeNotificationsService> pumpWarning(
    WidgetTester tester, {
    required bool notificationsEnabled,
    bool systemAllows = true,
    bool permissionGranted = true,
  }) async {
    final repo = FakeSettingsRepository(
      settings: buildAppSettings(notificationsEnabled: notificationsEnabled),
    );
    addTearDown(repo.close);
    final notifications = FakeNotificationsService()
      ..notificationsAllowed = systemAllows
      ..notificationPermissionGranted = permissionGranted;

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: ReminderWarning()),
        ),
        GoRoute(
          path: Routes.settings,
          builder: (context, state) =>
              const Scaffold(body: Text('Pantalla de ajustes')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(repo),
          notificationsServiceProvider.overrideWithValue(notifications),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pumpAndSettle();
    return notifications;
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

  testWidgets('pulsarlo con los avisos apagados lleva a Ajustes', (
    tester,
  ) async {
    final notifications = await pumpWarning(
      tester,
      notificationsEnabled: false,
    );

    await tester.tap(find.textContaining('Avisos apagados'));
    await tester.pumpAndSettle();

    // La salida es el ajuste, no el permiso: no hay nada que pedirle al sistema.
    expect(find.text('Pantalla de ajustes'), findsOneWidget);
    expect(notifications.requestNotificationPermissionCalls, 0);
  });

  testWidgets('pulsarlo con el sistema bloqueando pide el permiso', (
    tester,
  ) async {
    final notifications = await pumpWarning(
      tester,
      notificationsEnabled: true,
      systemAllows: false,
    );

    await tester.tap(find.textContaining('El sistema bloquea'));
    await tester.pumpAndSettle();

    expect(notifications.requestNotificationPermissionCalls, 1);
    // Concedido: el sistema ya deja mostrarlos, así que el aviso se va.
    expect(find.textContaining('El sistema bloquea'), findsNothing);
  });

  testWidgets('si el sistema lo deniega, lo dice y el aviso sigue', (
    tester,
  ) async {
    await pumpWarning(
      tester,
      notificationsEnabled: true,
      systemAllows: false,
      permissionGranted: false,
    );

    await tester.tap(find.textContaining('El sistema bloquea'));
    await tester.pumpAndSettle();

    expect(find.textContaining('El sistema bloquea'), findsOneWidget);
    expect(find.textContaining('Sigue bloqueado'), findsOneWidget);
  });
}
