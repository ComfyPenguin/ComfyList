import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/notifications/notifications_provider.dart';
import 'polling_registry.dart';

/// Pausa y reanuda el [PollingRegistry] cuando la app pasa a background /
/// vuelve a foreground, evitando errores transitorios de red y auth en el
/// primer tick tras resume.
class AppLifecycleController {
  AppLifecycleController(this._ref) {
    _listener = AppLifecycleListener(onStateChange: _onStateChange);
  }

  final Ref _ref;
  late final AppLifecycleListener _listener;

  void _onStateChange(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // El sistema puede ocultar el teclado mientras la app estaba en
        // segundo plano, pero conservar el foco del campo. Lo liberamos al
        // volver para que el layout no se quede con un inset fantasma.
        FocusManager.instance.primaryFocus?.unfocus();
        _ref.read(pollingRegistryProvider).resume();
        // Los permisos se cambian en los ajustes del sistema, así que pudieron
        // cambiar mientras la app estaba fuera: hay que volver a preguntarlos.
        _ref.invalidate(exactAlarmsGrantedProvider);
        _ref.invalidate(systemAllowsNotificationsProvider);
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.inactive:
        // Al salir de la app, cerramos el teclado y eliminamos el foco antes
        // de que el sistema congele el estado de los insets de la ventana.
        FocusManager.instance.primaryFocus?.unfocus();
        if (state == AppLifecycleState.paused ||
            state == AppLifecycleState.hidden) {
          _ref.read(pollingRegistryProvider).pause();
        }
      case AppLifecycleState.detached:
        break;
    }
  }

  void dispose() {
    _listener.dispose();
  }
}

final appLifecycleControllerProvider = Provider<AppLifecycleController>((ref) {
  final controller = AppLifecycleController(ref);
  ref.onDispose(controller.dispose);
  return controller;
});
