import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../features/appointments/presentation/providers/appointments_provider.dart';
import '../features/appointments/presentation/providers/appointments_state.dart';
import '../features/appointments/presentation/screens/appointment_edit_screen.dart';
import '../features/appointments/presentation/screens/appointments_screen.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/auth/presentation/providers/auth_state.dart';
import '../features/auth/presentation/screens/sign_in_screen.dart';
import '../features/todo_lists/presentation/providers/todo_lists_provider.dart';
import '../features/todo_lists/presentation/providers/todo_lists_state.dart';
import '../features/auth/presentation/screens/sign_up_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/todo_lists/presentation/screens/todo_list_edit_screen.dart';
import '../features/todo_lists/presentation/screens/todo_lists_screen.dart';
import '../features/todos/presentation/screens/todo_edit_screen.dart';
import '../features/todos/presentation/screens/todos_screen.dart';
import '../shared/core/theme/app_theme.dart';
import '../shared/ui/navigation/app_shell.dart';
import 'routes.dart';

/// Adapta el estado de auth y datos al `Listenable` de GoRouter.
///
/// Escuchar los providers de datos aquí tiene dos efectos: los inicializa de
/// forma no-lazy (arrancan en cuanto auth resuelve) y notifica al router cada
/// vez que cambian, permitiendo que el redirect espere a que estén listos.
class _AppStateListenable extends ChangeNotifier {
  _AppStateListenable(this._ref) {
    _ref.listen<AuthState>(authProvider, (_, _) => notifyListeners());
    _ref.listen<TodoListsState>(todoListsProvider, (_, _) => notifyListeners());
    _ref.listen<AppointmentsState>(
        appointmentsProvider, (_, _) => notifyListeners());
  }
  final Ref _ref;
}

/// Página sin animación de transición. Todas las navegaciones son instantáneas.
Page<void> _instantPage(Widget child) {
  return CustomTransitionPage<void>(
    child: child,
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
    transitionsBuilder: (_, _, _, child) => child,
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  final listenable = _AppStateListenable(ref);

  return GoRouter(
    initialLocation: Routes.home,
    refreshListenable: listenable,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final loggingIn = state.matchedLocation == Routes.signIn ||
          state.matchedLocation == Routes.signUp;

      // Mientras el bootstrap (auto-login) decide, no redirigimos:
      // _HomeGate muestra el splash hasta que haya veredicto.
      if (auth is AuthInitial || auth is AuthLoading) return null;

      final isAuth = auth is Authenticated;
      if (!isAuth && !loggingIn) return Routes.signIn;
      if (isAuth && loggingIn) return Routes.home;

      // Auth en / redirige a /lists solo cuando los datos ya están precargados.
      // Esto evita el spinner post-splash en las pantallas de contenido.
      if (isAuth && state.matchedLocation == Routes.home) {
        final lists = ref.read(todoListsProvider);
        final appts = ref.read(appointmentsProvider);

        final listsReady = lists is TodoListsData || lists is TodoListsError;
        final apptsReady = appts is AppointmentsData || appts is AppointmentsError;

        if (!listsReady || !apptsReady) return null;

        return Routes.todoLists;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: Routes.home,
        pageBuilder: (context, state) => _instantPage(const _HomeGate()),
      ),
      GoRoute(
        path: Routes.signIn,
        pageBuilder: (context, state) => _instantPage(const SignInScreen()),
      ),
      GoRoute(
        path: Routes.signUp,
        pageBuilder: (context, state) => _instantPage(const SignUpScreen()),
      ),

      // Pantalla de ajustes fuera del shell (pantalla limpia sin BottomBar).
      GoRoute(
        path: Routes.settings,
        pageBuilder: (context, state) => _instantPage(const SettingsScreen()),
      ),

      // Rutas de citas fuera del shell (pantalla limpia sin TopBar ni
      // BottomBar). Se declaran ANTES del ShellRoute para que GoRouter
      // resuelva los segmentos literales (`/appointments/new`,
      // `/appointments/:id/edit`) antes que el comodín `/appointments` del
      // shell, evitando que `:id` capture el literal `new`.
      GoRoute(
        path: Routes.appointmentNew,
        pageBuilder: (context, state) =>
            _instantPage(const AppointmentEditScreen()),
      ),
      GoRoute(
        path: '/appointments/:id/edit',
        pageBuilder: (context, state) => _instantPage(
            AppointmentEditScreen(id: state.pathParameters['id'])),
      ),

      // Shell persistente: TopBar + BottomBar + FAB compartidos.
      ShellRoute(
        builder: (context, state, child) =>
            AppShell(routerState: state, child: child),
        routes: [
          GoRoute(
            path: Routes.todoLists,
            pageBuilder: (context, state) =>
                _instantPage(const TodoListsScreen()),
          ),
          // Declarada antes de `/lists/:listId` para que el literal `new` no
          // sea capturado por el parámetro `:listId`.
          GoRoute(
            path: Routes.todoListNew,
            pageBuilder: (context, state) =>
                _instantPage(const TodoListEditScreen()),
          ),
          GoRoute(
            path: '/lists/:listId',
            pageBuilder: (context, state) => _instantPage(
                TodosScreen(listId: state.pathParameters['listId']!)),
            routes: [
              GoRoute(
                path: 'edit',
                pageBuilder: (context, state) => _instantPage(
                    TodoListEditScreen(id: state.pathParameters['listId'])),
              ),
              GoRoute(
                path: 'todos/new',
                pageBuilder: (context, state) => _instantPage(
                    TodoEditScreen(listId: state.pathParameters['listId']!)),
              ),
              GoRoute(
                path: 'todos/:todoId',
                pageBuilder: (context, state) => _instantPage(TodoEditScreen(
                  listId: state.pathParameters['listId']!,
                  id: state.pathParameters['todoId'],
                )),
              ),
            ],
          ),
          GoRoute(
            path: Routes.appointments,
            pageBuilder: (context, state) =>
                _instantPage(const AppointmentsScreen()),
          ),
        ],
      ),
    ],
  );
});

/// Gate de la ruta raíz. Muestra [SplashScreen] mientras el auto-login
/// resuelve; el [redirect] del router se encarga de navegar a `/lists`
/// cuando la sesión está activa.
class _HomeGate extends StatelessWidget {
  const _HomeGate();

  @override
  Widget build(BuildContext context) => const _SplashScreen();
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          // SizedBox externo fuerza el tamaño del stack; el Lottie usa
          // Positioned.fill para ocupar TODA la caja (sin esto, el lottie
          // se renderiza a su tamaño intrínseco 50x50 y se ve diminuto).
          child: SizedBox(
            width: 350,
            height: 350,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: Lottie.asset(
                    'assets/lottie/loading.json',
                    fit: BoxFit.contain,
                    // Sobrescribimos los strokes verdes del lottie con
                    // tokens del tema, para que se adapten a claro/oscuro.
                    delegates: LottieDelegates(
                      values: [
                        ValueDelegate.strokeColor(
                          const ['**', 'Stroke'],
                          value: context.colors.body,
                        ),
                      ],
                    ),
                  ),
                ),
                Image.asset(
                  'assets/logo-face.png',
                  width: 140,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
