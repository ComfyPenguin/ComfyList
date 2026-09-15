import 'package:comfy_list/features/settings/domain/entities/app_settings.dart';
import 'package:comfy_list/features/settings/domain/repositories/settings_repository.dart';
import 'package:comfy_list/features/settings/presentation/providers/settings_provider.dart';
import 'package:comfy_list/features/settings/presentation/screens/settings_screen.dart';
import 'package:comfy_list/shared/core/failures/failure.dart';
import 'package:comfy_list/shared/core/theme/app_theme.dart';
import 'package:comfy_list/shared/ui/inputs/app_switch.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Repositorio que falla en la primera lectura y responde a partir de la
/// segunda, para comprobar el reintento del aviso de error.
class _FakeSettingsRepository implements SettingsRepository {
  int loadCalls = 0;
  bool fail = true;

  @override
  Future<AppSettings> load() async {
    loadCalls++;
    if (fail) throw const CacheFailure();
    return AppSettings.defaults;
  }

  @override
  Stream<AppSettings> watch() => const Stream.empty();

  @override
  Future<void> setAppointmentsCompletedToBottom(bool enabled) async {}

  @override
  Future<void> setAppointmentsCompletionEnabled(bool enabled) async {}

  @override
  Future<void> setCompletedToBottom(bool enabled) async {}

  @override
  Future<void> setInvertSwipeActions(bool enabled) async {}

  @override
  Future<void> setNotificationsEnabled(bool enabled) async {}

  @override
  Future<void> setThemeMode(ThemeMode mode) async {}

  @override
  Future<void> setUse24HourFormat(bool enabled) async {}
}

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

  testWidgets('el reintento recupera los ajustes sin salir de la pantalla', (
    tester,
  ) async {
    final repo = _FakeSettingsRepository();

    tester.view.physicalSize = const Size(1170, 4200);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

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

    expect(repo.loadCalls, 1);
    expect(find.text('No se han podido leer tus ajustes.'), findsOneWidget);
    expect(disabledSwitches(tester), 5);

    repo.fail = false;
    await tester.tap(find.text('Reintentar'));
    await tester.pump();
    await tester.pump();
    await tester.pumpAndSettle();

    expect(repo.loadCalls, 2);
    expect(find.text('No se han podido leer tus ajustes.'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    // Con los datos leídos solo queda deshabilitado el ajuste que depende de
    // «Completar citas», que por defecto está apagado.
    expect(disabledSwitches(tester), 1);
    expect(tester.takeException(), isNull);
  });
}
