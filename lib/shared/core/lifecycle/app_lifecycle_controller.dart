import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/appointments/presentation/providers/appointments_provider.dart';
import '../../../features/todos/presentation/providers/todos_provider.dart';
import '../../../features/todo_lists/presentation/providers/todo_lists_provider.dart';
import '../../../features/trash/presentation/providers/trash_provider.dart';
import '../../data/notifications/notifications_provider.dart';
import 'polling_registry.dart';

/// Pausa y reanuda el polling de los repositorios de datos cuando la app
/// pasa a background / vuelve a foreground, evitando errores transitorios
/// de red y auth en el primer tick tras resume.
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
  // Mantenemos los repos vivos durante toda la vida de la app, incluso
  // cuando los Notifiers que los consumen no estén siendo observados
  // (p. ej. la familia de TodosProvider al cambiar entre listas).
  ref.read(appointmentsRepositoryProvider);
  ref.read(todosRepositoryProvider);
  ref.read(todoListsRepositoryProvider);
  ref.read(trashRepositoryProvider);

  final controller = AppLifecycleController(ref);
  ref.onDispose(controller.dispose);
  return controller;
});
