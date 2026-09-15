import 'package:comfy_list/shared/data/notifications/notifications_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/timezone.dart' as tz;

class _MockPlugin extends Mock implements FlutterLocalNotificationsPlugin {}

class _MockAndroidPlugin extends Mock
    implements AndroidFlutterLocalNotificationsPlugin {}

void main() {
  late _MockPlugin plugin;
  late _MockAndroidPlugin android;
  late NotificationsService service;

  setUpAll(() {
    // Los avisos son cosa de Android: con el reloj de la plataforma en Android
    // los caminos que pregunta al plugin se recorren de verdad.
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    registerFallbackValue(const InitializationSettings());
    registerFallbackValue(const NotificationDetails());
    registerFallbackValue(tz.TZDateTime.from(DateTime.utc(2026), tz.UTC));
    registerFallbackValue(AndroidScheduleMode.inexactAllowWhileIdle);
  });

  tearDownAll(() => debugDefaultTargetPlatformOverride = null);

  setUp(() {
    plugin = _MockPlugin();
    android = _MockAndroidPlugin();
    when(
      () => plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >(),
    ).thenReturn(android);
    service = NotificationsService(plugin: plugin);
  });

  void stubSchedule() {
    when(
      () => plugin.zonedSchedule(
        id: any(named: 'id'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        scheduledDate: any(named: 'scheduledDate'),
        notificationDetails: any(named: 'notificationDetails'),
        androidScheduleMode: any(named: 'androidScheduleMode'),
      ),
    ).thenAnswer((_) async {});
  }

  test('programa el aviso en el instante que se le pide', () async {
    stubSchedule();
    // Hora local del usuario: el aviso debe caer en ese mismo instante.
    final when = DateTime(2026, 9, 15, 11, 30);

    await service.schedule(
      id: 7,
      title: 'Análisis',
      body: 'Hoy a las 12:30',
      when: when,
    );

    final scheduled =
        verify(
              () => plugin.zonedSchedule(
                id: 7,
                title: 'Análisis',
                body: 'Hoy a las 12:30',
                scheduledDate: captureAny(named: 'scheduledDate'),
                notificationDetails: any(named: 'notificationDetails'),
                androidScheduleMode: any(named: 'androidScheduleMode'),
              ),
            ).captured.single
            as tz.TZDateTime;

    expect(scheduled.isUtc, isTrue);
    expect(
      scheduled.millisecondsSinceEpoch,
      when.millisecondsSinceEpoch,
      reason: 'El cambio de hora no debe desplazar el aviso.',
    );
  });

  test('quita un aviso por su id', () async {
    when(() => plugin.cancel(id: any(named: 'id'))).thenAnswer((_) async {});

    await service.cancel(7);

    verify(() => plugin.cancel(id: 7)).called(1);
  });

  test('preparar el plugin no pide ningún permiso', () async {
    when(
      () => plugin.initialize(settings: any(named: 'settings')),
    ).thenAnswer((_) async => true);

    await service.init();

    verify(() => plugin.initialize(settings: any(named: 'settings'))).called(1);
    verifyNever(() => android.requestNotificationsPermission());
  });

  test('pregunta al sistema si deja mostrar avisos', () async {
    when(
      () => android.areNotificationsEnabled(),
    ).thenAnswer((_) async => false);

    expect(await service.systemAllowsNotifications(), isFalse);
  });

  test('si el sistema no contesta no se da por permitido', () async {
    when(
      () => android.areNotificationsEnabled(),
    ).thenThrow(MissingPluginException('sin soporte'));

    expect(await service.systemAllowsNotifications(), isFalse);
  });

  test('el permiso de notificaciones lo concede el sistema', () async {
    when(
      () => android.requestNotificationsPermission(),
    ).thenAnswer((_) async => true);

    expect(await service.requestNotificationPermission(), isTrue);
  });

  test('un sistema que falla deja el permiso sin conceder', () async {
    when(
      () => android.requestNotificationsPermission(),
    ).thenThrow(MissingPluginException('sin soporte'));

    expect(await service.requestNotificationPermission(), isFalse);
  });

  test('sin el permiso del sistema el aviso se programa aproximado', () async {
    when(
      () => android.canScheduleExactNotifications(),
    ).thenAnswer((_) async => false);
    stubSchedule();

    await service.schedule(id: 1, title: 'x', body: 'y', when: DateTime(2030));

    verify(
      () => plugin.zonedSchedule(
        id: 1,
        title: 'x',
        body: 'y',
        scheduledDate: any(named: 'scheduledDate'),
        notificationDetails: any(named: 'notificationDetails'),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      ),
    ).called(1);
  });

  test('al concederlo, los avisos siguientes ya van exactos', () async {
    when(
      () => android.canScheduleExactNotifications(),
    ).thenAnswer((_) async => false);
    when(
      () => android.requestExactAlarmsPermission(),
    ).thenAnswer((_) async => true);
    stubSchedule();

    await service.schedule(id: 1, title: 'x', body: 'y', when: DateTime(2030));
    expect(await service.requestExactAlarms(), isTrue);
    await service.schedule(id: 2, title: 'x', body: 'y', when: DateTime(2030));

    // El modo se resuelve una vez por sesión: si no se olvidara la respuesta
    // anterior, el segundo aviso seguiría saliendo aproximado.
    verify(
      () => plugin.zonedSchedule(
        id: 2,
        title: 'x',
        body: 'y',
        scheduledDate: any(named: 'scheduledDate'),
        notificationDetails: any(named: 'notificationDetails'),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      ),
    ).called(1);
  });

  test('si el sistema no lo concede no se da por hecho', () async {
    when(
      () => android.requestExactAlarmsPermission(),
    ).thenAnswer((_) async => false);

    expect(await service.requestExactAlarms(), isFalse);
  });

  test('preguntar por el permiso no rompe donde no hay plugin', () async {
    when(
      () => android.canScheduleExactNotifications(),
    ).thenThrow(MissingPluginException('sin soporte'));

    expect(await service.canScheduleExact(), isFalse);
  });

  test('limpia los avisos sin tocar los ya mostrados', () async {
    when(() => plugin.cancelAllPendingNotifications()).thenAnswer((_) async {});

    await service.cancelAll();

    verify(() => plugin.cancelAllPendingNotifications()).called(1);
    verifyNever(() => plugin.cancelAll());
  });

  test('un plugin que falla no rompe la llamada', () async {
    when(
      () => plugin.zonedSchedule(
        id: any(named: 'id'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        scheduledDate: any(named: 'scheduledDate'),
        notificationDetails: any(named: 'notificationDetails'),
        androidScheduleMode: any(named: 'androidScheduleMode'),
      ),
    ).thenThrow(MissingPluginException('sin soporte'));

    // Best-effort: la app tiene que seguir funcionando donde no hay avisos.
    await expectLater(
      service.schedule(id: 1, title: 'x', body: 'y', when: DateTime(2030)),
      completes,
    );
  });
}
