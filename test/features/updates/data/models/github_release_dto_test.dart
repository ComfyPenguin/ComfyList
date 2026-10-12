import 'package:comfy_list/features/updates/data/models/github_release_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> asset(String name, {String? digest}) => {
    'name': name,
    'browser_download_url': 'https://example.test/download/$name',
    'digest': ?digest,
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

  test('recoge el sha256 que publica el asset', () {
    final parsed = GithubReleaseDto.fromJson(
      release(
        assets: [
          asset(
            'comfylist-2026.10.11+231.apk',
            digest:
                'sha256:2151b604e3429bff440b9fbc03eb3617bc2603cda96c95b9bb05277f9ddba255',
          ),
        ],
      ),
    ).toRelease();

    expect(
      parsed?.sha256,
      '2151b604e3429bff440b9fbc03eb3617bc2603cda96c95b9bb05277f9ddba255',
    );
  });

  test('un digest que no sea sha256 se ignora', () {
    final parsed = GithubReleaseDto.fromJson(
      release(
        assets: [
          asset('comfylist-2026.10.11+231.apk', digest: 'sha1:2151b604e3429bff'),
        ],
      ),
    ).toRelease();

    expect(parsed?.sha256, isNull);
  });

  test('sin digest la release no trae hash que comprobar', () {
    final parsed = GithubReleaseDto.fromJson(release()).toRelease();

    expect(parsed?.sha256, isNull);
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
