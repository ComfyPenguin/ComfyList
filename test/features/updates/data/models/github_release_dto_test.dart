import 'package:comfy_list/features/updates/data/models/github_release_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> asset(String name) => {
    'name': name,
    'browser_download_url': 'https://example.test/download/$name',
  };

  Map<String, dynamic> release({
    String tag = 'v2026.10.11.231',
    List<Map<String, dynamic>>? assets,
  }) => {
    'tag_name': tag,
    'body': '### Novedades\n',
    'published_at': '2026-10-11T18:40:29Z',
    'assets':
        assets ??
        [
          asset('comfylist-2026.10.11+231.aab'),
          asset('comfylist-2026.10.11+231.apk'),
        ],
  };

  test('coge el APK y no el AAB, con su URL de descarga', () {
    final parsed = GithubReleaseDto.fromJson(release()).toRelease();

    expect(parsed, isNotNull);
    expect(parsed!.assetName, 'comfylist-2026.10.11+231.apk');
    expect(parsed.downloadUrl, contains('comfylist-2026.10.11+231.apk'));
    expect(parsed.version, '2026.10.11');
    expect(parsed.build, 231);
    expect(parsed.publishedAt, DateTime.utc(2026, 10, 11, 18, 40, 29));
  });

  test('si el tag no dice la versión, la saca del nombre del APK', () {
    final parsed = GithubReleaseDto.fromJson(release(tag: 'nightly')).toRelease();

    expect(parsed?.version, '2026.10.11');
    expect(parsed?.build, 231);
  });

  test('sin APK no hay nada que instalar', () {
    final parsed = GithubReleaseDto.fromJson(
      release(assets: [asset('comfylist-2026.10.11+231.aab')]),
    ).toRelease();

    expect(parsed, isNull);
  });

  test('una release del versionado viejo se ignora', () {
    final parsed = GithubReleaseDto.fromJson(
      release(tag: 'v1.0.0', assets: [asset('comfylist-1.0.0.apk')]),
    ).toRelease();

    expect(parsed, isNull);
  });

  test('una respuesta sin los campos esperados no rompe', () {
    final parsed = GithubReleaseDto.fromJson(const {}).toRelease();

    expect(parsed, isNull);
  });
}
