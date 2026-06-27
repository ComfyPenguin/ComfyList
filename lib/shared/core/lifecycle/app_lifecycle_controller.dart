import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/appointments/presentation/providers/appointments_provider.dart';
import '../../../features/todos/presentation/providers/todos_provider.dart';
import '../../../features/todo_lists/presentation/providers/todo_lists_provider.dart';

/// Pausa y reanuda el polling de los repositorios de datos cuando la app
/// pasa a background / vuelve a foreground, evitando errores transitorios
/// de red y auth en el primer tick tras resume.
class AppLifecycleController {
  AppLifecycleController(this._ref) {
    _listener = AppLifecycleListener(
      onStateChange: _onStateChange,
    );
  }

  final Ref _ref;
  late final AppLifecycleListener _listener;

  void _onStateChange(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _ref.read(appointmentsRepositoryProvider).resumeAll();
        _ref.read(todosRepositoryProvider).resumeAll();
        _ref.read(todoListsRepositoryProvider).resumeAll();
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _ref.read(appointmentsRepositoryProvider).pauseAll();
        _ref.read(todosRepositoryProvider).pauseAll();
        _ref.read(todoListsRepositoryProvider).pauseAll();
      case AppLifecycleState.inactive:
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

  final controller = AppLifecycleController(ref);
  ref.onDispose(controller.dispose);
  return controller;
});
