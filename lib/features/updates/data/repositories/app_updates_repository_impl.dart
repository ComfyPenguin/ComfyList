import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

import '../../../../shared/core/failures/failure.dart';
import '../../../../shared/core/files/file_checksum.dart';
import '../../../../shared/core/result/result.dart';
import '../../domain/entities/app_release.dart';
import '../../domain/repositories/app_updates_repository.dart';
import '../datasources/apk_download_manager.dart';
import '../datasources/github_releases_remote.dart';

class AppUpdatesRepositoryImpl implements AppUpdatesRepository {
  AppUpdatesRepositoryImpl(
    this._remote,
    this._downloads, {
    Duration pollInterval = const Duration(milliseconds: 500),
    Duration stallTimeout = const Duration(minutes: 2),
  }) : _pollInterval = pollInterval,
       _stallTimeout = stallTimeout;

  final GithubReleasesRemote _remote;
  final ApkDownloadManager _downloads;

  /// Cada cuánto se pregunta al DownloadManager por el progreso.
  final Duration _pollInterval;

  /// Sin avanzar este tiempo (sin red, por ejemplo) se deja de esperar. La
  /// descarga sigue en el sistema y el reintento se reengancha a ella.
  final Duration _stallTimeout;

  @override
  Future<Result<AppRelease>> latestRelease() async {
    try {
      final release = await _remote.latestRelease();
      if (release == null) {
        return const Err(
          UnknownFailure('No se ha podido interpretar la última versión publicada.'),
        );
      }
      return Ok(release);
    } on DioException catch (e) {
      return Err(_failureFor(e));
    }
  }

  @override
  Future<Result<String>> downloadApk({
    required AppRelease release,
    void Function(int received, int total)? onProgress,
  }) async {
    try {
      final id = await _downloads.enqueue(
        url: release.downloadUrl,
        fileName: 'comfylist-${release.label}.apk',
        title: 'ComfyList ${release.label}',
      );

      var lastReceived = -1;
      final stalled = Stopwatch()..start();
      while (true) {
        final status = await _downloads.status(id);
        switch (status.phase) {
          case ApkDownloadPhase.running:
            if (status.received != lastReceived) {
              lastReceived = status.received;
              stalled.reset();
            } else if (stalled.elapsed >= _stallTimeout) {
              return const Err(
                NetworkFailure(
                  'La descarga no avanza. Revisa la conexión y vuelve a intentarlo.',
                ),
              );
            }
            onProgress?.call(status.received, status.total);
            await Future<void>.delayed(_pollInterval);
          case ApkDownloadPhase.failed:
            await _discard(id);
            return Err(_failureForReason(status.reason));
          case ApkDownloadPhase.successful:
            final path = status.path;
            if (path == null) {
              return const Err(CacheFailure('No se ha podido guardar la descarga.'));
            }
            if (!await _matchesPublishedHash(File(path), release.sha256)) {
              await _discard(id);
              return const Err(IntegrityFailure());
            }
            return Ok(path);
        }
      }
    } on PlatformException {
      return const Err(
        UnknownFailure('No se ha podido descargar la actualización.'),
      );
    } on MissingPluginException {
      return const Err(
        UnknownFailure('Esta plataforma no sabe descargar la actualización.'),
      );
    }
  }

  /// Comprueba el archivo bajado contra el hash que publica la release. Un
  /// APK que no se puede releer cuenta como no coincidente: el reintento vuelve
  /// a bajarlo con un archivo limpio.
  static Future<bool> _matchesPublishedHash(File file, String expected) async {
    try {
      final actual = await sha256OfFile(file);
      return actual.toLowerCase() == expected.toLowerCase();
    } on FileSystemException {
      return false;
    }
  }

  Future<void> _discard(int id) async {
    try {
      await _downloads.remove(id);
    } on PlatformException {
      // El fallo que ya se tiene es el que importa; la siguiente descarga
      // pisa la que no se pudo borrar.
    }
  }

  /// [reason] es el `COLUMN_REASON` del DownloadManager: un código HTTP o una
  /// de sus constantes `ERROR_*`.
  static Failure _failureForReason(int reason) => switch (reason) {
    // La descarga ya no existe: se canceló desde la notificación.
    0 => const UnknownFailure('Se ha cancelado la descarga.'),
    404 => const ServerFailure('No se ha encontrado la versión publicada.'),
    // ERROR_FILE_ERROR, ERROR_INSUFFICIENT_SPACE, ERROR_DEVICE_NOT_FOUND
    1001 || 1006 || 1007 => const CacheFailure(
      'No se ha podido guardar la descarga.',
    ),
    // ERROR_HTTP_DATA_ERROR, ERROR_CANNOT_RESUME
    1004 || 1008 => const NetworkFailure(),
    _ => const ServerFailure(),
  };

  Failure _failureFor(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return const TimeoutFailure();
    }
    // Una conexión que se corta a mitad llega como `unknown`.
    if (e.type == DioExceptionType.connectionError ||
        e.error is SocketException ||
        e.error is HttpException) {
      return const NetworkFailure();
    }
    if (e.response?.statusCode == 403) {
      return const ServerFailure(
        'GitHub ha limitado las peticiones. Inténtalo más tarde.',
      );
    }
    if (e.response?.statusCode == 404) {
      return const ServerFailure('No se ha encontrado la versión publicada.');
    }
    return const ServerFailure();
  }
}
