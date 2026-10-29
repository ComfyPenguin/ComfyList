import 'dart:io';

import 'package:comfy_list/features/updates/data/datasources/apk_download_manager.dart';
import 'package:comfy_list/features/updates/data/datasources/github_releases_remote.dart';
import 'package:comfy_list/features/updates/data/models/github_release_dto.dart';
import 'package:comfy_list/features/updates/data/repositories/app_updates_repository_impl.dart';
import 'package:comfy_list/features/updates/domain/entities/app_release.dart';
import 'package:comfy_list/shared/core/failures/failure.dart';
import 'package:comfy_list/shared/core/result/result.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/test_helpers.dart';

class _MockGithubReleasesRemote extends Mock implements GithubReleasesRemote {}

class _MockApkDownloadManager extends Mock implements ApkDownloadManager {}

// Lo que escribe el stub, con el sha256 que da `sha256sum` de ese contenido.
const content = 'APK de prueba de ComfyList';
const contentHash =
    'a8f872c6dbaae56fb57f94dc74502da8a14eb2257e3731ebb7ab6aff256edd8b';

void main() {
  late _MockGithubReleasesRemote remote;
  late _MockApkDownloadManager downloads;
  late Directory downloadsDir;

  setUp(() {
    remote = _MockGithubReleasesRemote();
    downloads = _MockApkDownloadManager();
    downloadsDir = Directory.systemTemp.createTempSync('comfylist-updates-test');
    when(() => downloads.remove(any())).thenAnswer((_) async {});
  });

  tearDown(() => downloadsDir.deleteSync(recursive: true));

  AppUpdatesRepositoryImpl buildRepo() =>
      AppUpdatesRepositoryImpl(remote, downloads, pollInterval: Duration.zero);

  DioException dioError(
    DioExceptionType type, {
    int? statusCode,
    Object? error,
  }) => DioException(
    requestOptions: RequestOptions(path: ''),
    type: type,
    error: error,
    response: statusCode == null
        ? null
        : Response<dynamic>(
            requestOptions: RequestOptions(path: ''),
            statusCode: statusCode,
          ),
  );

  void stubEnqueue() => when(
    () => downloads.enqueue(
      url: any(named: 'url'),
      fileName: any(named: 'fileName'),
      title: any(named: 'title'),
    ),
  ).thenAnswer((_) async => 7);

  /// Va devolviendo [statuses] en orden, como el DownloadManager al preguntarle
  /// varias veces.
  void stubStatuses(List<ApkDownloadStatus> statuses) {
    final queue = [...statuses];
    when(() => downloads.status(7)).thenAnswer((_) async => queue.removeAt(0));
  }

  /// Finge una descarga terminada con [content] en disco.
  void stubCompletedDownload({String content = ''}) {
    final file = File('${downloadsDir.path}/comfylist.apk')
      ..writeAsStringSync(content);
    stubEnqueue();
    stubStatuses([
      ApkDownloadStatus(phase: ApkDownloadPhase.successful, path: file.path),
    ]);
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

    test('una conexión cortada a mitad se traduce a NetworkFailure', () async {
      when(() => remote.latestRelease()).thenThrow(
        dioError(
          DioExceptionType.unknown,
          error: const HttpException('Connection closed while receiving data'),
        ),
      );

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
    test('encola la release y devuelve dónde quedó el APK', () async {
      stubCompletedDownload();
      final release = buildAppRelease();

      final result = await buildRepo().downloadApk(release: release);

      expect((result as Ok<String>).value, startsWith(downloadsDir.path));
      verify(
        () => downloads.enqueue(
          url: release.downloadUrl,
          fileName: 'comfylist-2026.10.11.231.apk',
          title: any(named: 'title'),
        ),
      ).called(1);
    });

    test('informa del progreso mientras el sistema descarga', () async {
      final file = File('${downloadsDir.path}/comfylist.apk')
        ..writeAsStringSync('');
      stubEnqueue();
      stubStatuses([
        const ApkDownloadStatus(
          phase: ApkDownloadPhase.running,
          received: 10,
          total: 100,
        ),
        const ApkDownloadStatus(
          phase: ApkDownloadPhase.running,
          received: 60,
          total: 100,
        ),
        ApkDownloadStatus(phase: ApkDownloadPhase.successful, path: file.path),
      ]);
      final progress = <int>[];

      final result = await buildRepo().downloadApk(
        release: buildAppRelease(),
        onProgress: (received, _) => progress.add(received),
      );

      expect(result, isA<Ok<String>>());
      expect(progress, [10, 60]);
    });

    test('una descarga fallida se limpia y explica el motivo', () async {
      stubEnqueue();
      stubStatuses([
        const ApkDownloadStatus(phase: ApkDownloadPhase.failed, reason: 1006),
      ]);

      final result = await buildRepo().downloadApk(release: buildAppRelease());

      expect((result as Err<String>).failure, isA<CacheFailure>());
      verify(() => downloads.remove(7)).called(1);
    });

    test('un corte de datos es un fallo de red', () async {
      stubEnqueue();
      stubStatuses([
        const ApkDownloadStatus(phase: ApkDownloadPhase.failed, reason: 1004),
      ]);

      final result = await buildRepo().downloadApk(release: buildAppRelease());

      expect((result as Err<String>).failure, isA<NetworkFailure>());
    });

    test('si deja de avanzar se deja de esperar sin cancelarla', () async {
      stubEnqueue();
      const stuck = ApkDownloadStatus(
        phase: ApkDownloadPhase.running,
        received: 10,
        total: 100,
      );
      stubStatuses([stuck, stuck]);

      final result = await AppUpdatesRepositoryImpl(
        remote,
        downloads,
        pollInterval: Duration.zero,
        stallTimeout: Duration.zero,
      ).downloadApk(release: buildAppRelease());

      expect((result as Err<String>).failure, isA<NetworkFailure>());
      verifyNever(() => downloads.remove(any()));
    });

    test('si no se puede borrar la fallida, manda su motivo', () async {
      stubEnqueue();
      stubStatuses([
        const ApkDownloadStatus(phase: ApkDownloadPhase.failed, reason: 404),
      ]);
      when(() => downloads.remove(any()))
          .thenThrow(PlatformException(code: 'downloadFailed'));

      final result = await buildRepo().downloadApk(release: buildAppRelease());

      expect((result as Err<String>).failure.message, contains('encontrado'));
    });

    test('cancelada desde la notificación lo dice así', () async {
      stubEnqueue();
      stubStatuses([const ApkDownloadStatus(phase: ApkDownloadPhase.failed)]);

      final result = await buildRepo().downloadApk(release: buildAppRelease());

      expect((result as Err<String>).failure.message, contains('cancelado'));
    });

    test('si el sistema no acepta la descarga no se queda colgada', () async {
      when(
        () => downloads.enqueue(
          url: any(named: 'url'),
          fileName: any(named: 'fileName'),
          title: any(named: 'title'),
        ),
      ).thenThrow(PlatformException(code: 'downloadFailed'));

      final result = await buildRepo().downloadApk(release: buildAppRelease());

      expect((result as Err<String>).failure, isA<UnknownFailure>());
    });
  });

  group('verifyApk', () {
    Future<String> downloaded() async {
      stubCompletedDownload(content: content);
      final result = await buildRepo().downloadApk(
        release: buildAppRelease(sha256: contentHash),
      );
      return (result as Ok<String>).value;
    }

    test('si el APK sigue igual, queda listo para instalar', () async {
      final path = await downloaded();

      final result = await buildRepo().verifyApk(
        release: buildAppRelease(sha256: contentHash),
        path: path,
      );

      expect(result, isA<Ok<void>>());
      expect(File(path).existsSync(), isTrue);
    });

    test('un APK cambiado tras la descarga se borra', () async {
      final path = await downloaded();
      File(path).writeAsStringSync('otro APK');

      final result = await buildRepo().verifyApk(
        release: buildAppRelease(sha256: contentHash),
        path: path,
      );

      expect((result as Err<void>).failure, isA<IntegrityFailure>());
      expect(File(path).existsSync(), isFalse);
    });

    test('un APK que ya no está no se lee como manipulación', () async {
      final path = '${downloadsDir.path}/no-existe.apk';

      final result = await buildRepo().verifyApk(
        release: buildAppRelease(sha256: contentHash),
        path: path,
      );

      final failure = (result as Err<void>).failure;
      expect(failure, isA<CacheFailure>());
      expect(failure, isNot(isA<IntegrityFailure>()));
      expect(failure.message, contains('ya no está disponible'));
    });

    test('el hash publicado en mayúsculas también cuadra', () async {
      final path = await downloaded();

      final result = await buildRepo().verifyApk(
        release: buildAppRelease(sha256: contentHash.toUpperCase()),
        path: path,
      );

      expect(result, isA<Ok<void>>());
    });
  });

  group('comprobación del hash publicado', () {
    test('con el hash de GitHub el APK queda listo para instalar', () async {
      stubCompletedDownload(content: content);

      final result = await buildRepo().downloadApk(
        release: buildAppRelease(sha256: contentHash),
      );

      expect(result, isA<Ok<String>>());
      expect(File((result as Ok<String>).value).existsSync(), isTrue);
    });

    test('si no cuadra, se borra la descarga', () async {
      stubCompletedDownload(content: content);

      final result = await buildRepo().downloadApk(
        release: buildAppRelease(sha256: 'f' * 64),
      );

      expect((result as Err<String>).failure, isA<IntegrityFailure>());
      verify(() => downloads.remove(7)).called(1);
    });

    test('un hash de otra descarga tampoco cuela', () async {
      stubCompletedDownload(content: 'otro APK distinto');

      final result = await buildRepo().downloadApk(
        release: buildAppRelease(sha256: contentHash),
      );

      expect((result as Err<String>).failure, isA<IntegrityFailure>());
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
            'browser_download_url':
                'https://github.com/ComfyPenguin/ComfyList/releases/download/'
                'v2026.10.11.231/comfylist-2026.10.11%2B231.apk',
            'digest': 'sha256:$contentHash',
          },
        ],
      }).toRelease();
      stubCompletedDownload(content: content);

      final result = await buildRepo().downloadApk(release: release!);

      expect(result, isA<Ok<String>>());
    });
  });
}
