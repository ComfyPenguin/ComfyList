import 'package:flutter/foundation.dart';

import '../../../../shared/core/failures/failure.dart';
import '../../domain/entities/app_release.dart';

@immutable
sealed class AppUpdatesState {
  const AppUpdatesState();

  /// La versión en juego, si el estado habla de alguna.
  AppRelease? get release => switch (this) {
    AppUpdatesAvailable(:final release) => release,
    AppUpdatesDownloading(:final release) => release,
    AppUpdatesReady(:final release) => release,
    _ => null,
  };
}

/// Todavía no se ha comprobado (o esta plataforma no sabe actualizarse).
class AppUpdatesInitial extends AppUpdatesState {
  const AppUpdatesInitial();
}

class AppUpdatesChecking extends AppUpdatesState {
  const AppUpdatesChecking();
}

class AppUpdatesUpToDate extends AppUpdatesState {
  const AppUpdatesUpToDate();
}

class AppUpdatesAvailable extends AppUpdatesState {
  const AppUpdatesAvailable(this.release);
  @override
  final AppRelease release;
}

class AppUpdatesDownloading extends AppUpdatesState {
  const AppUpdatesDownloading(this.release, this.progress);

  @override
  final AppRelease release;

  /// Avance de la descarga, de 0 a 1.
  final double progress;
}

class AppUpdatesReady extends AppUpdatesState {
  const AppUpdatesReady(this.release, this.filePath);

  @override
  final AppRelease release;

  /// Ruta del APK descargado que hay que abrir con el instalador.
  final String filePath;
}

class AppUpdatesFailed extends AppUpdatesState {
  const AppUpdatesFailed(this.failure, {this.release});

  final Failure failure;

  /// La versión que se estaba bajando, si el fallo fue durante la descarga:
  /// «Reintentar» vuelve a bajarla en vez de preguntar a GitHub otra vez.
  @override
  final AppRelease? release;
}
