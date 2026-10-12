import 'package:comfy_list/features/settings/presentation/providers/app_version_provider.dart';
import 'package:comfy_list/features/settings/presentation/providers/settings_provider.dart';
import 'package:comfy_list/features/settings/presentation/widgets/update_check_tile.dart';
import 'package:comfy_list/features/updates/domain/repositories/app_updates_repository.dart';
import 'package:comfy_list/features/updates/presentation/providers/app_updates_provider.dart';
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
    registerFallbackValue(buildAppRelease());
  });

  late FakeSettingsRepository settings;
  late _MockAppUpdatesRepository repository;

  setUp(() {
    settings = FakeSettingsRepository();
    repository = _MockAppUpdatesRepository();
    addTearDown(settings.close);
  });

  Future<void> pumpTile(WidgetTester tester, {int installedBuild = 230}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(settings),
          appUpdatesRepositoryProvider.overrideWithValue(repository),
          apkInstallerProvider.overrideWithValue(_MockApkInstaller()),
          updateCheckSupportedProvider.overrideWithValue(true),
          installedBuildProvider.overrideWith((ref) async => installedBuild),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: Center(child: SizedBox(width: 390, child: UpdateCheckTile())),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('con la última build instalada dice que está al día', (
    tester,
  ) async {
    when(
      () => repository.latestRelease(),
    ).thenAnswer((_) async => Ok(buildAppRelease(build: 231)));

    await pumpTile(tester, installedBuild: 231);

    expect(find.text('Buscar actualizaciones'), findsOneWidget);
    expect(find.text('Estás al día.'), findsOneWidget);
  });

  testWidgets('anuncia la versión nueva y la abre al tocar', (tester) async {
    when(
      () => repository.latestRelease(),
    ).thenAnswer((_) async => Ok(buildAppRelease(build: 231)));

    await pumpTile(tester);
    await tester.pumpAndSettle();

    expect(find.textContaining('2026.10.11.231'), findsOneWidget);

    await tester.tap(find.text('Buscar actualizaciones'));
    await tester.pumpAndSettle();

    expect(find.text('Hay una versión nueva'), findsOneWidget);
  });

  testWidgets('un fallo se puede reintentar', (tester) async {
    when(
      () => repository.latestRelease(),
    ).thenAnswer((_) async => const Err(NetworkFailure()));

    await pumpTile(tester);

    expect(find.text('No hay conexión. Inténtalo de nuevo.'), findsOneWidget);

    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    verify(() => repository.latestRelease()).called(2);
  });
}
