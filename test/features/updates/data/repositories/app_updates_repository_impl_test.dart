import 'dart:io';

import 'package:comfy_list/features/updates/data/datasources/github_releases_remote.dart';
import 'package:comfy_list/features/updates/data/models/github_release_dto.dart';
import 'package:comfy_list/features/updates/data/repositories/app_updates_repository_impl.dart';
import 'package:comfy_list/features/updates/domain/entities/app_release.dart';
import 'package:comfy_list/shared/core/failures/failure.dart';
import 'package:comfy_list/shared/core/result/result.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/test_helpers.dart';

class _MockGithubReleasesRemote extends Mock implements GithubReleasesRemote {}

void main() {
  late _MockGithubReleasesRemote remote;
  late Directory cache;

  setUpAll(() {
    registerFallbackValue(buildAppRelease());
    registerFallbackValue((int received, int total) {});
  });

  setUp(() {
    remote = _MockGithubReleasesRemote();
    cache = Directory.systemTemp.createTempSync('comfylist-updates-test');
  });

  tearDown(() => cache.deleteSync(recursive: true));

  AppUpdatesRepositoryImpl buildRepo() =>
      AppUpdatesRepositoryImpl(remote, cacheDirectory: () async => cache);

  DioException dioError(DioExceptionType type, {int? statusCode}) => DioException(
    requestOptions: RequestOptions(path: ''),
    type: type,
    response: statusCode == null
        ? null
        : Response<dynamic>(
            requestOptions: RequestOptions(path: ''),
            statusCode: statusCode,
          ),
  );

  /// Finge la descarga escribiendo [content] donde el repositorio pidió el
  /// archivo, como haría `Dio.download`.
  void stubDownload({String content = ''}) {
    when(
      () => remote.downloadApk(
        url: any(named: 'url'),
        path: any(named: 'path'),
        onProgress: any(named: 'onProgress'),
      ),
    ).thenAnswer((invocation) async {
      final path = invocation.namedArguments[#path] as String;
      File(path).writeAsStringSync(content);
    });
  }

  group('latestRelease', () {
    test('devuelve la release publicada', () async {
      when(() => remote.latestRelease()).thenAnswer((_) async => buildAppRelease());

      final result = await buildRepo().latestRelease();

      expect(result, isA<Ok<AppRelease>>());
      expect((result as Ok<AppRelease>).value.build, 231);
    });

    test('una release que no se entiende falla con un mensaje claro', () async {
      when(() => remote.latestRelease()).thenAnswer((_) async => null);

      final result = await buildRepo().latestRelease();

      expect(result, isA<Err<AppRelease>>());
      expect((result as Err<AppRelease>).failure.message, contains('interpretar'));
    });

    test('sin conexión se traduce a NetworkFailure', () async {
      when(() => remote.latestRelease())
          .thenThrow(dioError(DioExceptionType.connectionError));

      final result = await buildRepo().latestRelease();

      expect((result as Err<AppRelease>).failure, isA<NetworkFailure>());
    });

    test('el límite de peticiones de GitHub tiene su propio mensaje', () async {
      when(() => remote.latestRelease())
          .thenThrow(dioError(DioExceptionType.badResponse, statusCode: 403));

      final result = await buildRepo().latestRelease();

      expect((result as Err<AppRelease>).failure.message, contains('limitado'));
    });
  });

  group('downloadApk', () {
    test('deja el APK en la caché con la versión en el nombre', () async {
      stubDownload();
      final release = buildAppRelease();

      final result = await buildRepo().downloadApk(release: release);

      expect(result, isA<Ok<String>>());
      final path = (result as Ok<String>).value;
      expect(path, startsWith(cache.path));
      expect(path, endsWith('comfylist-2026.10.11.231.apk'));
      verify(
        () => remote.downloadApk(
          url: release.downloadUrl,
          path: path,
          onProgress: any(named: 'onProgress'),
        ),
      ).called(1);
    });

    test('sin sitio en el disco es un fallo de caché', () async {
      when(
        () => remote.downloadApk(
          url: any(named: 'url'),
          path: any(named: 'path'),
          onProgress: any(named: 'onProgress'),
        ),
      ).thenThrow(FileSystemException('sin espacio'));

      final result = await buildRepo().downloadApk(release: buildAppRelease());

      expect((result as Err<String>).failure, isA<CacheFailure>());
    });

    test('un timeout al bajar el APK se traduce a TimeoutFailure', () async {
      when(
        () => remote.downloadApk(
          url: any(named: 'url'),
          path: any(named: 'path'),
          onProgress: any(named: 'onProgress'),
        ),
      ).thenThrow(dioError(DioExceptionType.receiveTimeout));

      final result = await buildRepo().downloadApk(release: buildAppRelease());

      expect((result as Err<String>).failure, isA<TimeoutFailure>());
    });
  });

  group('comprobación del hash publicado', () {
    // Lo que escribe el stub, con el sha256 que da `sha256sum` de ese contenido.
    const content = 'APK de prueba de ComfyList';
    const contentHash =
        'a8f872c6dbaae56fb57f94dc74502da8a14eb2257e3731ebb7ab6aff256edd8b';

    test('con el hash de GitHub el APK queda listo para instalar', () async {
      stubDownload(content: content);

      final result = await buildRepo().downloadApk(
        release: buildAppRelease(sha256: contentHash),
      );

      expect(result, isA<Ok<String>>());
      expect(File((result as Ok<String>).value).existsSync(), isTrue);
    });

    test('si no cuadra, no se deja nada que instalar', () async {
      stubDownload(content: content);

      final result = await buildRepo().downloadApk(
        release: buildAppRelease(sha256: 'f' * 64),
      );

      expect((result as Err<String>).failure, isA<IntegrityFailure>());
      expect(cache.listSync(), isEmpty);
    });

    test('un hash de otra descarga tampoco cuela', () async {
      stubDownload(content: 'otro APK distinto');

      final result = await buildRepo().downloadApk(
        release: buildAppRelease(sha256: contentHash),
      );

      expect((result as Err<String>).failure, isA<IntegrityFailure>());
    });

    test('sin hash publicado la descarga se acepta como antes', () async {
      stubDownload(content: content);

      final result = await buildRepo().downloadApk(release: buildAppRelease());

      expect(result, isA<Ok<String>>());
    });

    test('de la respuesta de la API al APK verificado', () async {
      // Sin nada simulado por medio: el JSON que devuelve `/releases/latest`,
      // con el `digest` del asset, tiene que acabar en un APK que cuadra.
      final release = GithubReleaseDto.fromJson({
        'tag_name': 'v2026.10.11.231',
        'body': '### Novedades\n',
        'assets': [
          {
            'name': 'comfylist-2026.10.11+231.apk',
            'browser_download_url': 'https://example.test/apk',
            'digest': 'sha256:$contentHash',
          },
        ],
      }).toRelease();
      stubDownload(content: content);

      final result = await buildRepo().downloadApk(release: release!);

      expect(result, isA<Ok<String>>());
    });
  });
}
