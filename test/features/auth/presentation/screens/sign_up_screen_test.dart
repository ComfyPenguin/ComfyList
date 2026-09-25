import 'package:comfy_list/features/auth/presentation/providers/auth_provider.dart';
import 'package:comfy_list/features/auth/presentation/providers/auth_state.dart';
import 'package:comfy_list/features/auth/presentation/screens/sign_up_screen.dart';
import 'package:comfy_list/shared/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/provider_scope.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final loader = FontLoader('PlusJakartaSans')
      ..addFont(
        rootBundle.load('assets/fonts/PlusJakartaSans-VariableFont.ttf'),
      );
    await loader.load();
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    Size physicalSize = const Size(1170, 2400),
  }) async {
    tester.view.physicalSize = physicalSize;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Sin bootstrap: la pantalla solo necesita saber que no hay sesión.
          authProvider.overrideWith(
            () => StaticAuthNotifier(const Unauthenticated()),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const SignUpScreen(),
        ),
      ),
    );
    await tester.pump();
  }

  /// Rellena el formulario. Los campos aparecen en cascada conforme se
  /// rellena el anterior, así que hay que dejar acabar el slide.
  Future<void> fillForm(
    WidgetTester tester, {
    required String password,
    String? confirm,
    String email = 'ana@correo.com',
  }) async {
    await tester.enterText(find.byType(TextField).at(0), email);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.enterText(find.byType(TextField).at(1), password);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.enterText(find.byType(TextField).at(2), confirm ?? password);
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('los requisitos se van marcando mientras se escribe', (
    tester,
  ) async {
    await pumpScreen(tester);

    await fillForm(tester, password: 'abc123');

    expect(find.text('Al menos 8 caracteres'), findsOneWidget);
    expect(find.text('Al menos una letra'), findsOneWidget);
    expect(find.text('Al menos un número'), findsOneWidget);
    // 6 caracteres: letra y número ya están, la longitud no.
    expect(find.byIcon(Icons.check_circle_rounded), findsNWidgets(2));

    await tester.enterText(find.byType(TextField).at(1), 'contraseña1');
    await tester.pump();

    expect(find.byIcon(Icons.check_circle_rounded), findsNWidgets(3));
    expect(find.byIcon(Icons.circle_outlined), findsNothing);
  });

  testWidgets('una contraseña de seis caracteres ya no vale', (tester) async {
    await pumpScreen(tester);

    // Seis caracteres era el mínimo anterior (y el de Firebase).
    await fillForm(tester, password: 'abc123');
    // El botón pinta su etiqueta en mayúsculas.
    await tester.ensureVisible(find.text('CREAR CUENTA'));
    await tester.tap(find.text('CREAR CUENTA'));
    await tester.pump();

    expect(
      find.text('La contraseña no cumple los requisitos.'),
      findsOneWidget,
    );
    // Sigue en el registro: no se ha llamado a la API.
    expect(find.byType(SignUpScreen), findsOneWidget);
    expect(find.text('Al menos 8 caracteres'), findsOneWidget);

    // Al completarla, el aviso rojo se va solo: ya se ve todo en verde.
    await tester.enterText(find.byType(TextField).at(1), 'abc12345');
    await tester.pump();

    expect(
      find.text('La contraseña no cumple los requisitos.'),
      findsNothing,
    );
  });
}
