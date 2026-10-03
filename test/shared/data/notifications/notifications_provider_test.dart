import 'package:comfy_list/shared/data/notifications/notifications_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_notifications_service.dart';
import '../../../helpers/provider_scope.dart';

void main() {
  test('el permiso del sistema es el que contesta el sistema', () async {
    for (final allowed in [true, false]) {
      final notifications = FakeNotificationsService()
        ..notificationsAllowed = allowed;
      final container = createTestContainer(
        extra: [notificationsServiceProvider.overrideWithValue(notifications)],
      );

      expect(
        await container.read(systemAllowsNotificationsProvider.future),
        allowed,
      );
    }
  });

  test('volver a preguntarlo vale aunque nadie lo esté mirando', () async {
    final notifications = FakeNotificationsService()
      ..notificationsAllowed = false;
    final container = createTestContainer(
      extra: [notificationsServiceProvider.overrideWithValue(notifications)],
    );

    await container.read(systemAllowsNotificationsProvider.future);

    // El usuario lo concede en los ajustes del sistema: es lo que hace la app
    // al volver del background, cuando puede que nadie lo esté mirando.
    notifications.notificationsAllowed = true;
    expect(
      () => container.invalidate(systemAllowsNotificationsProvider),
      returnsNormally,
    );

    expect(
      await container.read(systemAllowsNotificationsProvider.future),
      isTrue,
    );
  });
}
