import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Pantalla centinela que representa un destino de navegación en los tests:
/// solo pinta [label], para comprobar a qué ruta llevó el gesto.
class RouteProbe extends StatelessWidget {
  const RouteProbe({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text(label)));
}

/// Router mínimo de test: monta [home] en [initialLocation] y una ruta
/// centinela por cada entrada de [probes] (ruta → etiqueta).
///
/// Las páginas usan transición instantánea, igual que la app, de modo que un
/// único `pump` baste tras navegar: con animaciones continuas en pantalla
/// (p. ej. la píldora de «hoy») `pumpAndSettle` nunca vuelve.
GoRouter buildTestRouter({
  required String initialLocation,
  required Widget home,
  Map<String, String> probes = const {},
}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(path: initialLocation, pageBuilder: (_, _) => _instantPage(home)),
      for (final probe in probes.entries)
        GoRoute(
          path: probe.key,
          pageBuilder: (_, _) => _instantPage(RouteProbe(label: probe.value)),
        ),
    ],
  );
}

Page<void> _instantPage(Widget child) => CustomTransitionPage<void>(
  child: child,
  transitionDuration: Duration.zero,
  reverseTransitionDuration: Duration.zero,
  transitionsBuilder: (_, _, _, child) => child,
);
