import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../../shared/core/failures/failure.dart';
import '../../../../shared/core/result/result.dart';
import '../../domain/entities/app_release.dart';
import '../../domain/repositories/app_updates_repository.dart';
import '../datasources/github_releases_remote.dart';

class AppUpdatesRepositoryImpl implements AppUpdatesRepository {
  AppUpdatesRepositoryImpl(
    this._remote, {
    Future<Directory> Function()? cacheDirectory,
  }) : _cacheDirectory = cacheDirectory ?? getTemporaryDirectory;

  final GithubReleasesRemote _remote;

  /// Carpeta donde deja el APK. Se inyecta en tests: `path_provider` es un
  /// plugin y no existe fuera de la app.
  final Future<Directory> Function() _cacheDirectory;

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
      final directory = await _cacheDirectory();
      final path = p.join(directory.path, 'comfylist-${release.label}.apk');
      await _remote.downloadApk(
        url: release.downloadUrl,
        path: path,
        onProgress: onProgress,
      );
      return Ok(path);
    } on DioException catch (e) {
      return Err(_failureFor(e));
    } on FileSystemException {
      return const Err(CacheFailure('No se ha podido guardar la descarga.'));
    }
  }

  Failure _failureFor(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return const TimeoutFailure();
    }
    if (e.type == DioExceptionType.connectionError) {
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
