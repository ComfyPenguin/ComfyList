import 'package:comfy_list/features/settings/presentation/providers/app_version_provider.dart';
import 'package:comfy_list/features/settings/presentation/providers/settings_provider.dart';
import 'package:comfy_list/features/updates/domain/repositories/app_updates_repository.dart';
import 'package:comfy_list/features/updates/presentation/providers/app_updates_provider.dart';
import 'package:comfy_list/features/updates/presentation/widgets/update_available_dialog.dart';
import 'package:comfy_list/features/updates/presentation/widgets/update_available_watcher.dart';
import 'package:comfy_list/shared/core/failures/failure.dart';
import 'package:comfy_list/shared/core/result/result.dart';
import 'package:comfy_list/shared/core/theme/app_theme.dart';
import 'package:comfy_list/shared/platform/apk_installer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/fake_settings_repository.dart';
import '../../../../helpers/test_helpers.dart';

class _MockAppUpdatesRepository extends Mock implements AppUpdatesRepository {}

class _MockApkInstaller extends Mock implements ApkInstaller {}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final loader = FontLoader('PlusJakartaSans')
      ..addFont(
        rootBundle.load('assets/fonts/PlusJakartaSans-VariableFont.ttf'),
      );
    await loader.load();
  });

  final release = buildAppRelease(
    build: 231,
    notes: '### Novedades\n- **listas**: se pueden reordenar\n',
  );

  late FakeSettingsRepository settings;
  late _MockAppUpdatesRepository repository;
  late _MockApkInstaller installer;

  setUpAll(() {
    registerFallbackValue(buildAppRelease());
    registerFallbackValue((int received, int total) {});
  });

  setUp(() {
    settings = FakeSettingsRepository();
    repository = _MockAppUpdatesRepository();
    installer = _MockApkInstaller();
    addTearDown(settings.close);
    when(
      () => installer.install(any()),
    ).thenAnswer((_) async => const Ok<void>(null));
  });

  // Sin tipo de retorno a propósito: `Override` no se exporta desde
  // `flutter_riverpod` y el tipo se infiere de la lista.
  overrides({bool supported = false, int installedBuild = 230}) => [
    settingsRepositoryProvider.overrideWithValue(settings),
    appUpdatesRepositoryProvider.overrideWithValue(repository),
    apkInstallerProvider.overrideWithValue(installer),
    updateCheckSupportedProvider.overrideWithValue(supported),
    installedBuildProvider.overrideWith((ref) async => installedBuild),
  ];

  Future<void> pumpDialog(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides(),
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () => UpdateAvailableDialog.show(context, release),
                  child: const Text('abrir'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('enseña la versión nueva y sus notas', (tester) async {
    await pumpDialog(tester);

    expect(find.text('Hay una versión nueva'), findsOneWidget);
    expect(find.text('ComfyList 2026.10.11.231'), findsOneWidget);
    expect(find.text('Novedades'), findsOneWidget);
    expect(find.text('• listas: se pueden reordenar'), findsOneWidget);
  });

  testWidgets('Actualizar baja el APK y el botón pasa a instalar', (tester) async {
    when(
      () => repository.downloadApk(
        release: any(named: 'release'),
        onProgress: any(named: 'onProgress'),
      ),
    ).thenAnswer((_) async => const Ok('/tmp/comfylist-2026.10.11.231.apk'));
    await pumpDialog(tester);

    await tester.tap(find.text('ACTUALIZAR'));
    await tester.pumpAndSettle();

    expect(find.text('INSTALAR'), findsOneWidget);

    await tester.tap(find.text('INSTALAR'));
    await tester.pumpAndSettle();

    verify(
      () => installer.install('/tmp/comfylist-2026.10.11.231.apk'),
    ).called(1);
  });

  testWidgets('si la descarga falla se puede reintentar', (tester) async {
    when(
      () => repository.downloadApk(
        release: any(named: 'release'),
        onProgress: any(named: 'onProgress'),
      ),
    ).thenAnswer((_) async => const Err(NetworkFailure()));
    await pumpDialog(tester);

    await tester.tap(find.text('ACTUALIZAR'));
    await tester.pumpAndSettle();

    expect(find.text('No hay conexión. Inténtalo de nuevo.'), findsOneWidget);
    expect(find.text('REINTENTAR'), findsOneWidget);

    await tester.tap(find.text('REINTENTAR'));
    await tester.pumpAndSettle();

    verify(
      () => repository.downloadApk(
        release: any(named: 'release'),
        onProgress: any(named: 'onProgress'),
      ),
    ).called(2);
  });

  testWidgets('si el APK no cuadra con el publicado, no se ofrece instalar', (
    tester,
  ) async {
    when(
      () => repository.downloadApk(
        release: any(named: 'release'),
        onProgress: any(named: 'onProgress'),
      ),
    ).thenAnswer((_) async => const Err(IntegrityFailure()));
    await pumpDialog(tester);

    await tester.tap(find.text('ACTUALIZAR'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('no coincide con el archivo publicado'),
      findsOneWidget,
    );
    expect(find.text('INSTALAR'), findsNothing);
    expect(find.text('REINTENTAR'), findsOneWidget);
  });

  testWidgets('«Ahora no» cierra el aviso y no vuelve a preguntar', (
    tester,
  ) async {
    await pumpDialog(tester);

    await tester.tap(find.text('Ahora no'));
    await tester.pumpAndSettle();

    expect(find.text('Hay una versión nueva'), findsNothing);
    expect((await settings.load()).skippedUpdateBuild, 231);
  });

  testWidgets('al abrir la app, el aviso sale solo', (tester) async {
    when(() => repository.latestRelease()).thenAnswer((_) async => Ok(release));

    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides(supported: true),
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: UpdateAvailableWatcher()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hay una versión nueva'), findsOneWidget);
    verify(() => repository.latestRelease()).called(1);
  });

  testWidgets('al abrir la app al día no sale nada', (tester) async {
    when(
      () => repository.latestRelease(),
    ).thenAnswer((_) async => Ok(release));

    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides(supported: true, installedBuild: 231),
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: UpdateAvailableWatcher()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hay una versión nueva'), findsNothing);
  });
}
