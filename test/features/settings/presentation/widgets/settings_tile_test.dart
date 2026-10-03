import 'package:comfy_list/features/settings/presentation/widgets/settings_tile.dart';
import 'package:comfy_list/shared/core/theme/app_theme.dart';
import 'package:comfy_list/shared/ui/inputs/app_switch.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // Con la fuente de verdad los renglones miden lo que miden: con la del
    // test cada glifo es un cuadrado y la descripción se partía en dos.
    final loader = FontLoader('PlusJakartaSans')
      ..addFont(
        rootBundle.load('assets/fonts/PlusJakartaSans-VariableFont.ttf'),
      );
    await loader.load();
  });

  Widget harness(Widget child) => MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(body: Center(child: SizedBox(width: 390, child: child))),
  );

  testWidgets('las filas de un renglón miden todas lo mismo', (tester) async {
    const bare = ValueKey('bare');
    const described = ValueKey('described');
    const switched = ValueKey('switched');

    await tester.pumpWidget(
      harness(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SettingsTile(
              key: bare,
              icon: Icons.restore_from_trash_outlined,
              title: 'Papelera',
            ),
            const SettingsTile(
              key: described,
              icon: Icons.restore_from_trash_outlined,
              title: 'Papelera',
              description: 'Borradas.',
            ),
            SettingsTile(
              key: switched,
              icon: Icons.notifications_outlined,
              title: 'Notificaciones',
              trailing: AppSwitch(value: false, onChanged: (_) {}),
            ),
          ],
        ),
      ),
    );

    // El switch no marca el alto —su área táctil, 44, es justo el mínimo de la
    // fila—, así que sin el mínimo la de solo título se quedaba más baja que
    // todas sus vecinas.
    final expected = tester.getSize(find.byKey(bare)).height;
    expect(tester.getSize(find.byKey(described)).height, expected);
    expect(tester.getSize(find.byKey(switched)).height, expected);
  });

  testWidgets('la fila con un control debajo sí es más alta', (tester) async {
    const bare = ValueKey('bare');
    const wide = ValueKey('wide');

    await tester.pumpWidget(
      harness(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SettingsTile(
              key: bare,
              icon: Icons.restore_from_trash_outlined,
              title: 'Papelera',
            ),
            const SettingsTile(
              key: wide,
              icon: Icons.auto_delete_outlined,
              title: 'Borrado automático',
              child: SizedBox(height: 44),
            ),
          ],
        ),
      ),
    );

    expect(
      tester.getSize(find.byKey(wide)).height,
      greaterThan(tester.getSize(find.byKey(bare)).height),
    );
  });
}
