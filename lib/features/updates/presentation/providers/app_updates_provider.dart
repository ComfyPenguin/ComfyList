import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/core/result/result.dart';
import '../../../../shared/core/time/clock.dart';
import '../../../../shared/platform/apk_installer.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../settings/domain/entities/app_settings.dart';
import '../../../settings/presentation/providers/app_version_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../settings/presentation/providers/settings_state.dart';
import '../../data/datasources/apk_download_manager.dart';
import '../../data/datasources/github_releases_remote.dart';
import '../../data/repositories/app_updates_repository_impl.dart';
import '../../domain/entities/app_release.dart';
import '../../domain/repositories/app_updates_repository.dart';
import 'app_updates_state.dart';

/// Cada cuánto se comprueba sola si hay versión nueva.
const Duration updateCheckInterval = Duration(days: 1);

/// El comprobador solo sirve donde hay APK que instalar: las releases publican
/// únicamente Android.
final updateCheckSupportedProvider = Provider<bool>(
  (ref) => !kIsWeb && Platform.isAndroid,
);

final githubReleasesRemoteProvider = Provider<GithubReleasesRemote>(
  (ref) => GithubReleasesRemote(ref.watch(dioClientProvider).authClient),
);

final appUpdatesRepositoryProvider = Provider<AppUpdatesRepository>(
  (ref) => AppUpdatesRepositoryImpl(
    ref.watch(githubReleasesRemoteProvider),
    const ApkDownloadManager(),
  ),
);

/// Instalador del sistema, sustituible en tests.
final apkInstallerProvider = Provider<ApkInstaller>(
  (ref) => const ApkInstaller(),
);

class AppUpdatesNotifier extends Notifier<AppUpdatesState> {
  AppUpdatesState _state = const AppUpdatesInitial();
  bool _autoCheckStarted = false;

  @override
  AppUpdatesState build() {
    // Las preferencias llegan después del primer frame: el arranque espera a
    // leerlas para respetar la caché y el «Ahora no». Va con `listen` y no con
    // un `watch` a secas porque el provider no se vuelve a leer solo, y la
    // comprobación tiene que salir igual.
    ref.listen(settingsProvider, (_, next) {
      if (next is SettingsData) _autoCheck();
    });
    if (ref.read(settingsProvider) is SettingsData) _autoCheck();

    // El estado sobrevive a los rebuilds del provider: sin esto, el resultado
    // de la comprobación se perdería al guardar cualquier preferencia.
    return _state;
  }

  void _autoCheck() {
    if (_autoCheckStarted || !ref.read(updateCheckSupportedProvider)) return;
    _autoCheckStarted = true;
    Future.microtask(() => check(respectCache: true));
  }

  /// Comprueba si hay versión nueva. Con [respectCache] no pregunta a GitHub si
  /// ya se comprobó hace menos de [updateCheckInterval] —lo que hace el
  /// arranque—; Ajustes siempre pregunta.
  Future<void> check({bool respectCache = false}) async {
    if (_state is AppUpdatesChecking) return;

    final installedBuild = await ref.read(installedBuildProvider.future);
    if (!ref.mounted || installedBuild == null) return;

    final now = ref.read(clockProvider)();
    if (respectCache && !_isCheckStale(now)) return;

    _set(const AppUpdatesChecking());
    final result = await ref.read(appUpdatesRepositoryProvider).latestRelease();
    if (!ref.mounted) return;

    switch (result) {
      case Ok(:final value):
        // Solo una comprobación que llega a algo cuenta para la caché: sin red,
        // el siguiente arranque lo vuelve a intentar.
        await _rememberCheck(now);
        _set(
          value.isNewerThan(installedBuild)
              ? AppUpdatesAvailable(value)
              : const AppUpdatesUpToDate(),
        );
      case Err(:final failure):
        _set(AppUpdatesFailed(failure));
    }
  }

  /// Baja el APK de [release] y lo deja listo para instalar.
  Future<void> download(AppRelease release) async {
    if (_state is AppUpdatesDownloading) return;

    _set(AppUpdatesDownloading(release, 0));
    final result = await ref
        .read(appUpdatesRepositoryProvider)
        .downloadApk(
          release: release,
          onProgress: (received, total) {
            if (!ref.mounted || total <= 0) return;
            _set(AppUpdatesDownloading(release, received / total));
          },
        );
    if (!ref.mounted) return;

    switch (result) {
      case Ok(:final value):
        _set(AppUpdatesReady(release, value));
      case Err(:final failure):
        _set(AppUpdatesFailed(failure, release: release));
    }
  }

  /// Lanza el instalador del sistema con el APK ya descargado.
  Future<void> install() async {
    final ready = _state;
    if (ready is! AppUpdatesReady) return;

    final result = await ref.read(apkInstallerProvider).install(ready.filePath);
    if (!ref.mounted) return;

    if (result case Err(:final failure)) {
      _set(AppUpdatesFailed(failure, release: ready.release));
    }
  }

  /// «Ahora no»: esa build deja de preguntar al abrir la app, aunque Ajustes
  /// siga anunciándola.
  Future<void> skip(AppRelease release) async {
    await ref
        .read(settingsProvider.notifier)
        .setSkippedUpdateBuild(release.build);
  }

  bool _isCheckStale(DateTime now) {
    final last = switch (ref.read(settingsProvider)) {
      SettingsData(:final settings) => settings.lastUpdateCheckAt,
      _ => null,
    };
    return last == null || now.difference(last) >= updateCheckInterval;
  }

  Future<void> _rememberCheck(DateTime at) async {
    if (ref.read(settingsProvider) is! SettingsData) return;
    await ref.read(settingsProvider.notifier).setLastUpdateCheckAt(at);
  }

  void _set(AppUpdatesState next) {
    if (!ref.mounted) return;
    _state = next;
    state = next;
  }
}

final appUpdatesProvider =
    NotifierProvider<AppUpdatesNotifier, AppUpdatesState>(
      AppUpdatesNotifier.new,
    );

/// La versión que toca preguntar al abrir la app; `null` cuando no hay nada que
/// preguntar (está al día, ya se descartó o ya se avisó en este arranque).
///
/// El aviso se marca al leerse por primera vez, así que sale una sola vez por
/// build y sesión sin que la UI tenga que acordarse de nada.
class UpdatePromptNotifier extends Notifier<AppRelease?> {
  int? _promptedBuild;

  /// El aviso ya está montado: se consume para que no se repita mientras el
  /// diálogo siga abierto.
  void consume() => state = null;

  @override
  AppRelease? build() {
    final release = switch (ref.watch(appUpdatesProvider)) {
      AppUpdatesAvailable(:final release) => release,
      _ => null,
    };
    if (release == null) return null;

    final skipped = switch (ref.watch(settingsProvider)) {
      SettingsData(:final settings) => settings.skippedUpdateBuild,
      _ => noSkippedUpdateBuild,
    };
    if (release.build == skipped || release.build == _promptedBuild) return null;

    _promptedBuild = release.build;
    return release;
  }
}

final updatePromptProvider =
    NotifierProvider<UpdatePromptNotifier, AppRelease?>(
      UpdatePromptNotifier.new,
    );
