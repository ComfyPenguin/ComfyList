import 'package:comfy_list/shared/core/files/file_checksum.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../tool/verify_release.dart';

void main() {
  // Sha256 de «APK de prueba de ComfyList», el mismo vector que usa el test del
  // cálculo (`sha256sum` coincide con él).
  const compilado =
      'a8f872c6dbaae56fb57f94dc74502da8a14eb2257e3731ebb7ab6aff256edd8b';

  PublishedAsset asset(String name, String? digest) =>
      PublishedAsset(name: name, digest: digest);

  group('parseArgs', () {
    test('el tag va el primero y el resto son archivos', () {
      final parsed = parseArgs([
        'v2026.10.11.231',
        'dist/comfylist-2026.10.11+231.apk',
        'dist/comfylist-2026.10.11+231.aab',
      ]);

      expect(parsed?.tag, 'v2026.10.11.231');
      expect(parsed?.files, [
        'dist/comfylist-2026.10.11+231.apk',
        'dist/comfylist-2026.10.11+231.aab',
      ]);
    });

    test('sin archivos que comprobar no hay nada que hacer', () {
      expect(parseArgs(['v2026.10.11.231']), isNull);
      expect(parseArgs(const []), isNull);
    });
  });

  group('sha256FromDigest', () {
    test('lee el hash del digest que publica GitHub', () {
      expect(sha256FromDigest('sha256:$compilado'), compilado);
    });

    test('normaliza a minúsculas', () {
      expect(sha256FromDigest('sha256:${compilado.toUpperCase()}'), compilado);
    });

    test('otro algoritmo se ignora: no se sabe comprobarlo', () {
      expect(sha256FromDigest('sha1:2151b604e3429bff'), isNull);
      expect(sha256FromDigest('md5:2151b604'), isNull);
    });

    test('sin digest, o vacío, tampoco hay hash', () {
      expect(sha256FromDigest(null), isNull);
      expect(sha256FromDigest('sha256:'), isNull);
      expect(sha256FromDigest('sha256:   '), isNull);
    });
  });

  group('digestProblems', () {
    test('cuando lo subido es lo compilado no hay nada que decir', () {
      final problems = digestProblems(
        localHashes: {'comfylist-2026.10.11+231.apk': compilado},
        published: [asset('comfylist-2026.10.11+231.apk', 'sha256:$compilado')],
      );

      expect(problems, isEmpty);
    });

    test('un hash distinto se denuncia con los dos valores', () {
      final problems = digestProblems(
        localHashes: {'comfylist-2026.10.11+231.apk': compilado},
        published: [
          asset('comfylist-2026.10.11+231.apk', 'sha256:${'f' * 64}'),
        ],
      );

      expect(problems, hasLength(1));
      expect(problems.single, contains('comfylist-2026.10.11+231.apk'));
      expect(problems.single, contains('publicado ${'f' * 64}'));
      expect(problems.single, contains('compilado $compilado'));
    });

    test('un archivo que no se ha subido se denuncia', () {
      final problems = digestProblems(
        localHashes: {'comfylist-2026.10.11+231.apk': compilado},
        published: [asset('comfylist-2026.10.11+231.aab', 'sha256:$compilado')],
      );

      expect(problems.single, contains('no está entre los assets'));
    });

    test('una release sin digest no permite dar nada por bueno', () {
      final problems = digestProblems(
        localHashes: {'comfylist-2026.10.11+231.apk': compilado},
        published: [asset('comfylist-2026.10.11+231.apk', null)],
      );

      expect(problems.single, contains('no publica un sha256'));
    });

    test('se mira cada archivo, no solo el primero', () {
      final problems = digestProblems(
        localHashes: {
          'comfylist-2026.10.11+231.apk': compilado,
          'comfylist-2026.10.11+231.aab': compilado,
        },
        published: [
          asset('comfylist-2026.10.11+231.apk', 'sha256:$compilado'),
          asset('comfylist-2026.10.11+231.aab', 'sha256:${'f' * 64}'),
        ],
      );

      expect(problems, hasLength(1));
      expect(problems.single, contains('.aab'));
    });
  });
}
