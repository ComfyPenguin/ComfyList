import 'package:comfy_list/features/settings/domain/entities/app_settings.dart';
import 'package:comfy_list/features/settings/domain/repositories/settings_repository.dart';
import 'package:comfy_list/features/settings/presentation/providers/app_version_provider.dart';
import 'package:comfy_list/features/settings/presentation/providers/settings_provider.dart';
import 'package:comfy_list/features/settings/presentation/providers/settings_state.dart';
import 'package:comfy_list/features/updates/domain/entities/app_release.dart';
import 'package:comfy_list/features/updates/domain/repositories/app_updates_repository.dart';
import 'package:comfy_list/features/updates/presentation/providers/app_updates_provider.dart';
import 'package:comfy_list/features/updates/presentation/providers/app_updates_state.dart';
import 'package:comfy_list/shared/core/failures/failure.dart';
import 'package:comfy_list/shared/core/result/result.dart';
import 'package:comfy_list/shared/core/time/clock.dart';
import 'package:comfy_list/shared/platform/apk_installer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/fake_settings_repository.dart';
import '../../../../helpers/provider_scope.dart';
import '../../../../helpers/test_helpers.dart';

class _MockAppUpdatesRepository extends Mock implements AppUpdatesRepository {}

class _MockApkInstaller extends Mock implements ApkInstaller {}

void main() {
  final now = DateTime.utc(2026, 10, 12, 12);
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
    when(() => installer.install(any())).thenAnswer((_) async => const Ok<void>(null));
    when(
      () => repository.verifyApk(
        release: any(named: 'release'),
        path: any(named: 'path'),
      ),
    ).thenAnswer((_) async => const Ok<void>(null));
  });

  /// Contenedor con el comprobador como si corriera en Android, con la build
  /// instalada fijada y sin red.
  ProviderContainer buildContainer({int installedBuild = 230, AppSettings? saved}) {
    if (saved != null) settings = FakeSettingsRepository(settings: saved);
    return createTestContainer(
      repositoryOverrides: {SettingsRepository: settings},
      extra: [
        appUpdatesRepositoryProvider.overrideWithValue(repository),
        apkInstallerProvider.overrideWithValue(installer),
        updateCheckSupportedProvider.overrideWithValue(true),
        installedBuildProvider.overrideWith((ref) async => installedBuild),
        clockProvider.overrideWithValue(() => now),
      ],
    );
  }

  void stubLatest(AppRelease release) {
    when(() => repository.latestRelease()).thenAnswer((_) async => Ok(release));
  }

  void stubLatestFailure() {
    when(() => repository.latestRelease())
        .thenAnswer((_) async => const Err(NetworkFailure()));
  }

  void stubDownload({String path = '/tmp/comfylist.apk'}) {
    when(
      () => repository.downloadApk(
        release: any(named: 'release'),
        onProgress: any(named: 'onProgress'),
      ),
    ).thenAnswer((_) async => Ok(path));
  }

  group('comprobación al arrancar', () {
    test('sin comprobación previa pregunta a GitHub y anuncia lo que hay', () async {
      stubLatest(buildAppRelease(build: 231));
      final container = buildContainer();

      container.read(appUpdatesProvider);
      await pumpEventQueue();

      expect(container.read(appUpdatesProvider), isA<AppUpdatesAvailable>());
      expect(
        (container.read(appUpdatesProvider) as AppUpdatesAvailable).release.build,
        231,
      );
      expect(
        switch (container.read(settingsProvider)) {
          SettingsData(:final settings) => settings.lastUpdateCheckAt,
          _ => null,
        },
        now,
      );
    });

    test('con la comprobación de hace una hora no molesta a la API', () async {
      final container = buildContainer(
        saved: buildAppSettings(
          lastUpdateCheckAt: now.subtract(const Duration(hours: 1)),
        ),
      );

      container.read(appUpdatesProvider);
      await pumpEventQueue();

      expect(container.read(appUpdatesProvider), isA<AppUpdatesInitial>());
      verifyNever(() => repository.latestRelease());
    });

    test('pasado el día vuelve a preguntar', () async {
      stubLatest(buildAppRelease(build: 231));
      final container = buildContainer(
        saved: buildAppSettings(
          lastUpdateCheckAt: now.subtract(const Duration(hours: 25)),
        ),
      );

      container.read(appUpdatesProvider);
      await pumpEventQueue();

      expect(container.read(appUpdatesProvider), isA<AppUpdatesAvailable>());
      verify(() => repository.latestRelease()).called(1);
    });

    test('con la última build instalada queda al día', () async {
      stubLatest(buildAppRelease(build: 231));
      final container = buildContainer(installedBuild: 231);

      container.read(appUpdatesProvider);
      await pumpEventQueue();

      expect(container.read(appUpdatesProvider), isA<AppUpdatesUpToDate>());
    });

    test('un build local más nuevo que la release no ofrece bajar nada', () async {
      stubLatest(buildAppRelease(build: 231));
      final container = buildContainer(installedBuild: 240);

      container.read(appUpdatesProvider);
      await pumpEventQueue();

      expect(container.read(appUpdatesProvider), isA<AppUpdatesUpToDate>());
    });

    test('si falla no marca la comprobación: el próximo arranque reintenta', () async {
      stubLatestFailure();
      final container = buildContainer();

      container.read(appUpdatesProvider);
      await pumpEventQueue();

      expect(container.read(appUpdatesProvider), isA<AppUpdatesFailed>());
      expect(
        switch (container.read(settingsProvider)) {
          SettingsData(:final settings) => settings.lastUpdateCheckAt,
          _ => null,
        },
        isNull,
      );
    });

    test('Ajustes pregunta aunque la caché esté fresca', () async {
      stubLatest(buildAppRelease(build: 231));
      final container = buildContainer(
        saved: buildAppSettings(lastUpdateCheckAt: now),
      );

      container.read(appUpdatesProvider);
      await pumpEventQueue();
      await container.read(appUpdatesProvider.notifier).check();

      verify(() => repository.latestRelease()).called(1);
      expect(container.read(appUpdatesProvider), isA<AppUpdatesAvailable>());
    });
  });

  group('descarga e instalación', () {
    test('informa del avance y deja el APK listo', () async {
      final release = buildAppRelease(build: 231);
      when(
        () => repository.downloadApk(
          release: any(named: 'release'),
          onProgress: any(named: 'onProgress'),
        ),
      ).thenAnswer((invocation) async {
        final onProgress =
            invocation.namedArguments[#onProgress]
                as void Function(int received, int total)?;
        onProgress?.call(25, 100);
        onProgress?.call(100, 100);
        return const Ok('/tmp/comfylist-2026.10.11.231.apk');
      });

      final container = buildContainer(saved: buildAppSettings(lastUpdateCheckAt: now));
      final seen = <AppUpdatesState>[];
      container.listen(appUpdatesProvider, (_, next) => seen.add(next));

      await container.read(appUpdatesProvider.notifier).download(release);
      await pumpEventQueue();

      expect(
        seen.whereType<AppUpdatesDownloading>().map((state) => state.progress),
        contains(0.25),
      );
      final state = container.read(appUpdatesProvider);
      expect(state, isA<AppUpdatesReady>());
      expect((state as AppUpdatesReady).filePath, endsWith('.apk'));
    });

    test('si la descarga falla se puede reintentar la misma versión', () async {
      when(
        () => repository.downloadApk(
          release: any(named: 'release'),
          onProgress: any(named: 'onProgress'),
        ),
      ).thenAnswer((_) async => const Err(NetworkFailure()));

      final container = buildContainer(saved: buildAppSettings(lastUpdateCheckAt: now));
      final release = buildAppRelease(build: 231);

      await container.read(appUpdatesProvider.notifier).download(release);
      await pumpEventQueue();

      final state = container.read(appUpdatesProvider);
      expect(state, isA<AppUpdatesFailed>());
      expect((state as AppUpdatesFailed).release?.build, 231);
    });

    test('instalar abre el instalador del sistema con el APK bajado', () async {
      stubDownload(path: '/tmp/comfylist.apk');
      final container = buildContainer(saved: buildAppSettings(lastUpdateCheckAt: now));
      final notifier = container.read(appUpdatesProvider.notifier);

      await notifier.download(buildAppRelease(build: 231));
      await notifier.install();

      verify(() => installer.install('/tmp/comfylist.apk')).called(1);
    });

    test('si el APK ya no cuadra, no se instala y se puede reintentar', () async {
      stubDownload(path: '/tmp/comfylist.apk');
      when(
        () => repository.verifyApk(
          release: any(named: 'release'),
          path: any(named: 'path'),
        ),
      ).thenAnswer((_) async => const Err(IntegrityFailure()));
      final container = buildContainer(saved: buildAppSettings(lastUpdateCheckAt: now));
      final notifier = container.read(appUpdatesProvider.notifier);
      final release = buildAppRelease(build: 231);

      await notifier.download(release);
      await notifier.install();

      final state = container.read(appUpdatesProvider);
      expect(state, isA<AppUpdatesFailed>());
      expect((state as AppUpdatesFailed).failure, isA<IntegrityFailure>());
      expect(state.release, release);
      verify(
        () => repository.verifyApk(release: release, path: '/tmp/comfylist.apk'),
      ).called(1);
      verifyNever(() => installer.install(any()));

      await notifier.download(release);

      expect(container.read(appUpdatesProvider), isA<AppUpdatesReady>());
    });

    test('si el instalador no puede, se cuenta en el estado', () async {
      stubDownload(path: '/tmp/comfylist.apk');
      when(() => installer.install(any())).thenAnswer(
        (_) async => const Err(
          UnknownFailure('Activa «Instalar apps desconocidas» para ComfyList.'),
        ),
      );
      final container = buildContainer(saved: buildAppSettings(lastUpdateCheckAt: now));
      final notifier = container.read(appUpdatesProvider.notifier);

      await notifier.download(buildAppRelease(build: 231));
      await notifier.install();

      expect(container.read(appUpdatesProvider), isA<AppUpdatesFailed>());
    });

    test('«Ahora no» guarda la build descartada', () async {
      final container = buildContainer(saved: buildAppSettings(lastUpdateCheckAt: now));

      await container.read(appUpdatesProvider.notifier).skip(
        buildAppRelease(build: 231),
      );
      await pumpEventQueue();

      expect(
        switch (container.read(settingsProvider)) {
          SettingsData(:final settings) => settings.skippedUpdateBuild,
          _ => noSkippedUpdateBuild,
        },
        231,
      );
    });
  });

  group('aviso al abrir la app', () {
    test('la versión nueva se avisa y el aviso se consume', () async {
      stubLatest(buildAppRelease(build: 231));
      final container = buildContainer();

      container.read(appUpdatesProvider);
      await pumpEventQueue();

      expect(container.read(updatePromptProvider)?.build, 231);

      container.read(updatePromptProvider.notifier).consume();

      expect(container.read(updatePromptProvider), isNull);
    });

    test('la versión descartada no vuelve a avisar', () async {
      stubLatest(buildAppRelease(build: 231));
      final container = buildContainer(
        saved: buildAppSettings(skippedUpdateBuild: 231),
      );

      container.read(appUpdatesProvider);
      await pumpEventQueue();

      expect(container.read(updatePromptProvider), isNull);
    });

    test('al día no hay nada que avisar', () async {
      stubLatest(buildAppRelease(build: 231));
      final container = buildContainer(installedBuild: 231);

      container.read(appUpdatesProvider);
      await pumpEventQueue();

      expect(container.read(updatePromptProvider), isNull);
    });
  });
}
