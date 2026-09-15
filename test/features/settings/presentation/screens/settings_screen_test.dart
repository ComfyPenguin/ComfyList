import 'package:comfy_list/features/settings/presentation/providers/settings_provider.dart';
import 'package:comfy_list/features/settings/presentation/screens/settings_screen.dart';
import 'package:comfy_list/features/settings/presentation/widgets/settings_tile.dart';
import 'package:comfy_list/shared/core/theme/app_theme.dart';
import 'package:comfy_list/shared/ui/animations/unfold_down.dart';
import 'package:comfy_list/shared/ui/inputs/app_switch.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fake_settings_repository.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final loader = FontLoader('PlusJakartaSans')
      ..addFont(
        rootBundle.load('assets/fonts/PlusJakartaSans-VariableFont.ttf'),
      );
    await loader.load();
  });

  int disabledSwitches(WidgetTester tester) {
    return tester
        .widgetList<AppSwitch>(find.byType(AppSwitch))
        .where((s) => s.onChanged == null)
        .length;
  }

  Future<void> pumpSettings(
    WidgetTester tester,
    FakeSettingsRepository repo,
  ) async {
    tester.view.physicalSize = const Size(1170, 4200);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    addTearDown(repo.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [settingsRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Center(
            child: SizedBox(width: 390, child: SettingsScreen()),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('el reintento recupera los ajustes sin salir de la pantalla', (
    tester,
  ) async {
    // El repo arranca fallando: el primer load lanza y sale el aviso.
    final repo = FakeSettingsRepository()..fail = true;
    await pumpSettings(tester, repo);

    expect(repo.loadCalls, 1);
    expect(find.text('No se han podido leer tus ajustes.'), findsOneWidget);
    // Sin poder leer las preferencias no se sabe si «Citas completadas al
    // final» toca montarla, así que su switch no cuenta.
    expect(disabledSwitches(tester), 5);

    repo.fail = false;
    await tester.tap(find.text('Reintentar'));
    await tester.pump();
    await tester.pump();
    await tester.pumpAndSettle();

    expect(repo.loadCalls, 2);
    expect(find.text('No se han podido leer tus ajustes.'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    // «Citas completadas al final» cuelga de «Completar citas», que por defecto
    // está apagado: la fila queda recogida, sin alto y sin responder al toque.
    expect(find.text('Citas completadas al final').hitTestable(), findsNothing);
    expect(disabledSwitches(tester), 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('las citas completadas al final se despliegan al activar '
      '«Completar citas»', (tester) async {
    final repo = FakeSettingsRepository();
    await pumpSettings(tester, repo);
    await tester.pumpAndSettle();

    // La fila cuelga de «Completar citas», apagado por defecto: recogida no se
    // puede pulsar y su bloque mide cero.
    final row = find.text('Citas completadas al final');
    final rowTop = tester.getTopLeft(row);
    expect(row.hitTestable(), findsNothing);
    expect(tester.getSize(find.byType(UnfoldDown)).height, 0);

    await tester.tap(
      find.descendant(
        of: find.ancestor(
          of: find.text('Completar citas'),
          matching: find.byType(SettingsTile),
        ),
        matching: find.byType(AppSwitch),
      ),
    );
    await tester.pump();

    // A media animación el bloque ya ocupa, pero menos que la fila entera, y la
    // fila sigue donde estaba: el despliegue la descubre, no la desplaza.
    await tester.pump(const Duration(milliseconds: 80));
    final revealing = tester.getSize(find.byType(UnfoldDown)).height;
    expect(revealing, greaterThan(0));
    expect(tester.getTopLeft(row), rowTop);

    await tester.pumpAndSettle();
    expect(row.hitTestable(), findsOneWidget);
    expect(
      tester.getSize(find.byType(UnfoldDown)).height,
      greaterThan(revealing),
    );
  });
}
