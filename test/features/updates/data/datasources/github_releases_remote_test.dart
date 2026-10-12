import 'package:comfy_list/features/updates/data/datasources/github_releases_remote.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/dio_mock.dart';

void main() {
  late MockDio dio;
  late GithubReleasesRemote remote;

  setUp(() {
    dio = MockDio();
    remote = GithubReleasesRemote(dio);
  });

  Map<String, dynamic> releaseJson() => {
    'tag_name': 'v2026.10.11.231',
    'body': '### Novedades\n- una cosa\n',
    'published_at': '2026-10-11T18:40:29Z',
    'assets': [
      {
        'name': 'comfylist-2026.10.11+231.apk',
        // El `+` viaja codificado en la URL que devuelve la API.
        'browser_download_url':
            'https://github.com/ComfyPenguin/ComfyList/releases/download/'
                'v2026.10.11.231/comfylist-2026.10.11%2B231.apk',
      },
    ],
  };

  test('traduce la respuesta a una release comparable', () async {
    stubDioGet(dio, body: releaseJson());

    final release = await remote.latestRelease();

    expect(release?.version, '2026.10.11');
    expect(release?.build, 231);
    expect(release?.downloadUrl, contains('comfylist-2026.10.11%2B231.apk'));
    expect(release?.notes, contains('Novedades'));
  });

  test('manda las cabeceras que la API de GitHub exige', () async {
    stubDioGet(dio, body: releaseJson());

    await remote.latestRelease();

    final options =
        verify(
              () => dio.get<Map<String, dynamic>>(
                captureAny(),
                options: captureAny(named: 'options'),
                cancelToken: any(named: 'cancelToken'),
              ),
            ).captured[1]
            as Options?;
    expect(options?.headers?['Accept'], 'application/vnd.github+json');
    expect(options?.headers?['User-Agent'], isNotEmpty);
  });

  test('una respuesta sin release utilizables devuelve null', () async {
    stubDioGet(dio, body: const {});

    expect(await remote.latestRelease(), isNull);
  });
}
