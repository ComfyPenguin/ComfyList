import 'package:comfy_list/shared/data/notifications/notifications_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/timezone.dart' as tz;

class _MockPlugin extends Mock implements FlutterLocalNotificationsPlugin {}

void main() {
  late _MockPlugin plugin;
  late NotificationsService service;

  setUpAll(() {
    registerFallbackValue(const NotificationDetails());
    registerFallbackValue(tz.TZDateTime.from(DateTime.utc(2026), tz.UTC));
    registerFallbackValue(AndroidScheduleMode.inexactAllowWhileIdle);
  });

  setUp(() {
    plugin = _MockPlugin();
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
