import '../../domain/entities/app_release.dart';

/// Respuesta de `/repos/{repo}/releases/latest`.
class GithubReleaseDto {
  const GithubReleaseDto({
    required this.tagName,
    required this.body,
    required this.assets,
    this.publishedAt,
  });

  factory GithubReleaseDto.fromJson(Map<String, dynamic> json) {
    final assets = (json['assets'] as List?) ?? const [];
    return GithubReleaseDto(
      tagName: json['tag_name'] as String? ?? '',
      body: json['body'] as String? ?? '',
      assets: assets
          .whereType<Map<String, dynamic>>()
          .map(GithubReleaseAssetDto.fromJson)
          .toList(growable: false),
      publishedAt: DateTime.tryParse(json['published_at'] as String? ?? ''),
    );
  }

  final String tagName;
  final String body;
  final List<GithubReleaseAssetDto> assets;
  final DateTime? publishedAt;

  /// Traduce la release a algo comparable e instalable. `null` si no hay APK
  /// (el AAB es para Play y no se instala a mano) o si el tag no dice qué
  /// versión es.
  AppRelease? toRelease() {
    GithubReleaseAssetDto? apk;
    for (final asset in assets) {
      if (asset.name.endsWith('.apk')) {
        apk = asset;
        break;
      }
    }
    if (apk == null) return null;

    final version =
        AppRelease.versionFromTag(tagName) ??
        AppRelease.versionFromAssetName(apk.name);
    final build =
        AppRelease.buildFromTag(tagName) ??
        AppRelease.buildFromAssetName(apk.name);
    if (version == null || build == null) return null;

    return AppRelease(
      version: version,
      build: build,
      notes: body.trim(),
      downloadUrl: apk.downloadUrl,
      assetName: apk.name,
      publishedAt: publishedAt?.toUtc(),
    );
  }
}

class GithubReleaseAssetDto {
  const GithubReleaseAssetDto({required this.name, required this.downloadUrl});

  factory GithubReleaseAssetDto.fromJson(Map<String, dynamic> json) =>
      GithubReleaseAssetDto(
        name: json['name'] as String? ?? '',
        // Ya viene con el `+` del nombre codificado: no se construye a mano.
        downloadUrl: json['browser_download_url'] as String? ?? '',
      );

  final String name;
  final String downloadUrl;
}
