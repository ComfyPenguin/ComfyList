import 'package:comfy_list/features/settings/presentation/providers/settings_provider.dart';
import 'package:comfy_list/features/settings/presentation/widgets/trash_retention_selector.dart';
import 'package:comfy_list/shared/core/theme/app_theme.dart';
import 'package:comfy_list/shared/ui/inputs/app_segmented_control.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fake_settings_repository.dart';
import '../../../../helpers/test_helpers.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // Con la fuente de verdad las cuatro opciones miden lo que miden de verdad:
    // son las que aprietan la fila.
    final loader = FontLoader('PlusJakartaSans')
      ..addFont(
        rootBundle.load('assets/fonts/PlusJakartaSans-VariableFont.ttf'),
      );
    await loader.load();
  });

  /// Monta el selector con el plazo guardado que se le pase y devuelve el repo
  /// para mirar lo que se guarda.
  Future<FakeSettingsRepository> pumpSelector(
    WidgetTester tester, {
    int? retentionDays,
  }) async {
    final repo = FakeSettingsRepository(
      settings: buildAppSettings(trashRetentionDays: retentionDays),
    );
    addTearDown(repo.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [settingsRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: Center(
              child: SizedBox(width: 390, child: TrashRetentionSelector()),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    return repo;
  }

  AppSegmentedControl<int> control(WidgetTester tester) =>
      tester.widget<AppSegmentedControl<int>>(
        find.byType(AppSegmentedControl<int>),
      );

  testWidgets('ofrece los cuatro plazos', (tester) async {
    await pumpSelector(tester);

    for (final label in ['Nunca', '7 días', '15 días', '30 días']) {
      expect(find.text(label), findsOneWidget, reason: 'falta $label');
    }
  });

  testWidgets('arranca en el plazo de fábrica', (tester) async {
    await pumpSelector(tester);

    final selected = control(tester);
    expect(selected.options[selected.selectedIndex].label, '30 días');
  });

  testWidgets('muestra el plazo guardado', (tester) async {
    await pumpSelector(tester, retentionDays: 30);

    expect(control(tester).options[control(tester).selectedIndex].value, 30);
  });

  testWidgets('elegir un plazo lo guarda', (tester) async {
    final repo = await pumpSelector(tester);

    await tester.tap(find.text('15 días'));
    await tester.pumpAndSettle();

    expect((await repo.load()).trashRetentionDays, 15);
  });
}
