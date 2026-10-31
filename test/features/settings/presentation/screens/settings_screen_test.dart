import 'package:comfy_list/features/settings/presentation/providers/app_version_provider.dart';
import 'package:comfy_list/features/settings/presentation/providers/settings_provider.dart';
import 'package:comfy_list/features/settings/presentation/screens/settings_screen.dart';
import 'package:comfy_list/features/settings/presentation/widgets/settings_tile.dart';
import 'package:comfy_list/features/updates/domain/repositories/app_updates_repository.dart';
import 'package:comfy_list/features/updates/presentation/providers/app_updates_provider.dart';
import 'package:comfy_list/shared/core/result/result.dart';
import 'package:comfy_list/shared/core/theme/app_theme.dart';
import 'package:comfy_list/shared/data/notifications/notifications_provider.dart';
import 'package:comfy_list/shared/ui/animations/unfold_down.dart';
import 'package:comfy_list/shared/ui/inputs/app_switch.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mocktail/mocktail.dart';

import '../../../../helpers/fake_notifications_service.dart';
import '../../../../helpers/fake_settings_repository.dart';
import '../../../../helpers/test_helpers.dart';

class _MockAppUpdatesRepository extends Mock implements AppUpdatesRepository {}

void main() {
  late _MockAppUpdatesRepository updates;

  setUp(() {
    updates = _MockAppUpdatesRepository();
  });

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final loader = FontLoader('PlusJakartaSans')
      ..addFont(
        rootBundle.load('assets/fonts/PlusJakartaSans-VariableFont.ttf'),
      );
    await loader.load();
  });

  int disabledSwitches(WidgetTester tester) {
    return tester
        .widgetList<AppSwitch>(find.byType(AppSwitch))
        .where((s) => s.onChanged == null)
        .length;
  }

  /// Switch de la fila con ese título.
  Finder switchOf(String title) => find.descendant(
    of: find.ancestor(
      of: find.text(title),
      matching: find.byType(SettingsTile),
    ),
    matching: find.byType(AppSwitch),
  );

  /// Bloque de despliegue de la fila con ese título. La pantalla tiene uno por
  /// cada ajuste que cuelga de otro, así que hay que decir de cuál.
  Finder unfoldFor(String title) =>
      find.ancestor(of: find.text(title), matching: find.byType(UnfoldDown));

  bool switchValue(WidgetTester tester, String title) =>
      tester.widget<AppSwitch>(switchOf(title)).value;

  /// Enciende los avisos: el permiso del sistema lo concede el fake, así que la
  /// fila queda desplegada.
  Future<void> enableNotifications(WidgetTester tester) async {
    await tester.tap(switchOf('Notificaciones'));
    await tester.pumpAndSettle();
  }

  Future<void> pumpSettings(
    WidgetTester tester,
    FakeSettingsRepository repo, {
    FakeNotificationsService? notifications,
    bool withUpdateCheck = false,
  }) async {
    tester.view.physicalSize = const Size(1170, 4200);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    addTearDown(repo.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(repo),
          notificationsServiceProvider.overrideWithValue(
            notifications ?? FakeNotificationsService(),
          ),
          // El paquete instalado no existe en un test: la versión se fija aquí.
          appVersionLabelProvider.overrideWith((ref) async => '2026.10.11.221'),
          if (withUpdateCheck) ...[
            updateCheckSupportedProvider.overrideWithValue(true),
            installedBuildProvider.overrideWith((ref) async => 230),
            appUpdatesRepositoryProvider.overrideWithValue(updates),
          ],
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          // La pantalla vive dentro del Scaffold del shell, que es quien puede
          // mostrar los avisos emergentes.
          home: const Scaffold(
            body: Center(child: SizedBox(width: 390, child: SettingsScreen())),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('el pie de la pantalla dice la versión que corre', (tester) async {
    final repo = FakeSettingsRepository();
    await pumpSettings(tester, repo);
    await tester.pumpAndSettle();

    expect(find.text('Versión 2026.10.11.221'), findsOneWidget);
  });

  testWidgets('el reintento recupera los ajustes sin salir de la pantalla', (
    tester,
  ) async {
    // El repo arranca fallando: el primer load lanza y sale el aviso.
    final repo = FakeSettingsRepository()..fail = true;
    await pumpSettings(tester, repo);

    expect(repo.loadCalls, 1);
    expect(find.text('No se han podido leer tus ajustes.'), findsOneWidget);
    expect(disabledSwitches(tester), 5);

    repo.fail = false;
    await tester.tap(find.text('Reintentar'));
    await tester.pump();
    await tester.pump();
    await tester.pumpAndSettle();

    expect(repo.loadCalls, 2);
    expect(find.text('No se han podido leer tus ajustes.'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(
      find.text('Citas completadas al final').hitTestable(),
      findsOneWidget,
    );
    expect(disabledSwitches(tester), 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('completar citas ya no es un ajuste y «completadas al final» '
      'se ve siempre', (tester) async {
    final repo = FakeSettingsRepository();
    await pumpSettings(tester, repo);
    await tester.pumpAndSettle();

    expect(find.text('Completar citas'), findsNothing);
    final row = find.text('Citas completadas al final');
    expect(row.hitTestable(), findsOneWidget);
    expect(unfoldFor('Citas completadas al final'), findsNothing);

    expect(switchValue(tester, 'Citas completadas al final'), isTrue);
    await tester.tap(switchOf('Citas completadas al final'));
    await tester.pumpAndSettle();
    expect(switchValue(tester, 'Citas completadas al final'), isFalse);
  });

  testWidgets('las notificaciones despliegan los recordatorios de citas', (
    tester,
  ) async {
    final repo = FakeSettingsRepository();
    await pumpSettings(tester, repo);
    await tester.pumpAndSettle();

    // Los avisos vienen apagados de fábrica, así que los recordatorios están
    // recogidos y no dejan hueco.
    final row = find.text('Recordatorios');
    final unfold = unfoldFor('Recordatorios');
    expect(row.hitTestable(), findsNothing);
    expect(tester.getSize(unfold).height, 0);

    await enableNotifications(tester);

    // Al encenderlos no hay nada que programar todavía, pero la fila se
    // despliega y responde al toque.
    expect(row.hitTestable(), findsOneWidget);
    expect(tester.getSize(unfold).height, greaterThan(0));
  });

  testWidgets('el permiso del sistema se pide al encender los avisos', (
    tester,
  ) async {
    final notifications = FakeNotificationsService();
    final repo = FakeSettingsRepository();
    await pumpSettings(tester, repo, notifications: notifications);
    await tester.pumpAndSettle();

    // Con los avisos apagados no hay nada que pedir.
    expect(notifications.requestNotificationPermissionCalls, 0);

    await enableNotifications(tester);

    expect(notifications.requestNotificationPermissionCalls, 1);
    expect(switchValue(tester, 'Notificaciones'), isTrue);
  });

  testWidgets('si el sistema deniega el permiso la fila se queda apagada', (
    tester,
  ) async {
    final notifications = FakeNotificationsService()
      ..notificationPermissionGranted = false;
    final repo = FakeSettingsRepository();
    await pumpSettings(tester, repo, notifications: notifications);
    await tester.pumpAndSettle();

    await enableNotifications(tester);

    // Encenderlo sin permiso sería prometer avisos que el sistema no va a
    // mostrar, así que el ajuste no se guarda.
    expect(notifications.requestNotificationPermissionCalls, 1);
    expect(switchValue(tester, 'Notificaciones'), isFalse);
  });

  testWidgets('con el sistema bloqueando los avisos, la pantalla lo avisa', (
    tester,
  ) async {
    final repo = FakeSettingsRepository(
      settings: buildAppSettings(notificationsEnabled: true),
    );
    final notifications = FakeNotificationsService()
      ..notificationsAllowed = false;
    await pumpSettings(tester, repo, notifications: notifications);
    await tester.pumpAndSettle();

    expect(find.text('Avisos bloqueados'), findsOneWidget);
  });

  testWidgets('con el sistema dejándolos pasar no hay nada que avisar', (
    tester,
  ) async {
    final repo = FakeSettingsRepository(
      settings: buildAppSettings(notificationsEnabled: true),
    );
    await pumpSettings(tester, repo);
    await tester.pumpAndSettle();

    expect(find.text('Avisos bloqueados'), findsNothing);
  });

  testWidgets('el aviso se toca para pedir el permiso y desaparece', (
    tester,
  ) async {
    final repo = FakeSettingsRepository(
      settings: buildAppSettings(notificationsEnabled: true),
    );
    final notifications = FakeNotificationsService()
      ..notificationsAllowed = false;
    await pumpSettings(tester, repo, notifications: notifications);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Avisos bloqueados'));
    await tester.pumpAndSettle();

    expect(notifications.requestNotificationPermissionCalls, 1);
    // Concedido: el sistema ya deja mostrarlos, así que no queda nada que
    // avisar.
    expect(find.text('Avisos bloqueados'), findsNothing);
  });

  testWidgets('si el sistema sigue bloqueando, lo dice y el aviso sigue', (
    tester,
  ) async {
    final repo = FakeSettingsRepository(
      settings: buildAppSettings(notificationsEnabled: true),
    );
    final notifications = FakeNotificationsService()
      ..notificationsAllowed = false
      ..notificationPermissionGranted = false;
    await pumpSettings(tester, repo, notifications: notifications);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Avisos bloqueados'));
    await tester.pumpAndSettle();

    expect(find.text('Avisos bloqueados'), findsOneWidget);
    expect(find.textContaining('Sigue bloqueado'), findsOneWidget);
  });

  testWidgets('con los avisos apagados no se avisa del sistema', (
    tester,
  ) async {
    final repo = FakeSettingsRepository(
      settings: buildAppSettings(notificationsEnabled: false),
    );
    final notifications = FakeNotificationsService()
      ..notificationsAllowed = false;
    await pumpSettings(tester, repo, notifications: notifications);
    await tester.pumpAndSettle();

    // Si los tiene apagados el usuario, el arreglo está en la fila de arriba y
    // no en el sistema.
    expect(find.text('Avisos bloqueados'), findsNothing);
  });

  testWidgets('con el permiso de alarmas exactas no hay nada que pedir', (
    tester,
  ) async {
    final repo = FakeSettingsRepository();
    // Por defecto el fake lo da por concedido, como el sistema tras concederlo.
    await pumpSettings(tester, repo);
    await tester.pumpAndSettle();
    await enableNotifications(tester);

    expect(find.text('Alarmas exactas'), findsNothing);
  });

  testWidgets('concede las alarmas exactas y la fila desaparece', (
    tester,
  ) async {
    final notifications = FakeNotificationsService()
      ..exactAlarmsGranted = false;
    final repo = FakeSettingsRepository();
    await pumpSettings(tester, repo, notifications: notifications);
    await tester.pumpAndSettle();
    await enableNotifications(tester);

    // Sin el permiso la fila está debajo del recordatorio, que ya no cierra el
    // grupo.
    expect(find.text('Alarmas exactas'), findsOneWidget);

    await tester.tap(find.text('Alarmas exactas'));
    await tester.pumpAndSettle();

    // El toque lleva a la pantalla del sistema; al volver, el permiso ya está y
    // la fila no tiene nada que ofrecer.
    expect(notifications.requestExactAlarmsCalls, 1);
    expect(find.text('Alarmas exactas'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('donde la app sabe actualizarse sale la sección de la aplicación', (
    tester,
  ) async {
    when(
      () => updates.latestRelease(),
    ).thenAnswer((_) async => Ok(buildAppRelease(build: 231)));
    final repo = FakeSettingsRepository();

    await pumpSettings(tester, repo, withUpdateCheck: true);
    await tester.pumpAndSettle();

    expect(find.text('APLICACIÓN'), findsOneWidget);
    expect(find.text('Buscar actualizaciones'), findsOneWidget);
    expect(find.textContaining('2026.10.11.231'), findsOneWidget);
  });

  testWidgets('donde no, la sección no se monta', (tester) async {
    final repo = FakeSettingsRepository();

    await pumpSettings(tester, repo);
    await tester.pumpAndSettle();

    expect(find.text('APLICACIÓN'), findsNothing);
    expect(find.text('Buscar actualizaciones'), findsNothing);
  });
}
