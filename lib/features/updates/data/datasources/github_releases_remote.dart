import 'package:dio/dio.dart';

import '../../../../shared/core/env/update_endpoints.dart';
import '../../domain/entities/app_release.dart';
import '../models/github_release_dto.dart';

/// Releases de GitHub por REST.
///
/// Usa el cliente sin interceptor del `DioClient`: el token de Firebase solo
/// viaja a Firestore.
class GithubReleasesRemote {
  GithubReleasesRemote(this._dio);

  final Dio _dio;

  /// Última release publicada, o `null` si no hay APK o el tag no se sabe
  /// interpretar.
  Future<AppRelease?> latestRelease() async {
    final res = await _dio.get<Map<String, dynamic>>(
      UpdateEndpoints.latestReleaseUrl,
      options: Options(headers: _headers),
    );
    final body = res.data;
    if (body == null) return null;
    return GithubReleaseDto.fromJson(body).toRelease();
  }

  Future<void> downloadApk({
    required String url,
    required String path,
    void Function(int received, int total)? onProgress,
  }) async {
    await _dio.download(
      url,
      path,
      onReceiveProgress: onProgress,
      options: Options(receiveTimeout: _downloadTimeout),
    );
  }

  static const Map<String, String> _headers = {
    'Accept': 'application/vnd.github+json',
    'X-GitHub-Api-Version': '2022-11-28',
    // GitHub rechaza las peticiones que no llevan User-Agent.
    'User-Agent': 'ComfyList',
  };

  /// Un APK de release pasa de 30 MB: el timeout normal se queda corto.
  static const Duration _downloadTimeout = Duration(minutes: 10);
}
