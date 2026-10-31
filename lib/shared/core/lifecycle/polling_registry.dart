import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Algo que sondea y se puede pausar: lo que se apunta en [PollingRegistry].
abstract interface class PollingMember {
  void pause();
  void resume();
}

/// Registro de sondeo: pausa y reanuda a la vez todo lo que sondea.
///
/// Recuerda también si está en pausa ([isPaused]): quien empiece a sondear con
/// la app en segundo plano debe consultarlo y esperar al [resume], o lanzaría
/// peticiones contra sockets que el sistema ya mató.
class PollingRegistry {
  final Set<PollingMember> _members = {};
  bool _paused = false;

  bool get isPaused => _paused;

  void register(PollingMember member) => _members.add(member);

  void unregister(PollingMember member) => _members.remove(member);

  void pause() {
    _paused = true;
    // Copia: un miembro puede darse de baja al reaccionar.
    for (final member in _members.toList()) {
      member.pause();
    }
  }

  void resume() {
    _paused = false;
    for (final member in _members.toList()) {
      member.resume();
    }
  }
}

/// Un único registro para toda la app; lo pausa [AppLifecycleController].
final pollingRegistryProvider = Provider<PollingRegistry>(
  (ref) => PollingRegistry(),
);
