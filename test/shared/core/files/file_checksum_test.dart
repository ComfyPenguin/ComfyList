import 'dart:io';

import 'package:comfy_list/shared/core/files/file_checksum.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('comfylist-checksum'));
  tearDown(() => dir.deleteSync(recursive: true));

  Future<String> hashOf(List<int> bytes) async {
    final file = File('${dir.path}/file.bin')..writeAsBytesSync(bytes);
    return sha256OfFile(file);
  }

  group('sha256OfFile', () {
    test('da el mismo hash que `sha256sum`', () async {
      // Vectores del núcleo de GNU: texto vacío y «abc».
      expect(
        await hashOf(const []),
        'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      );
      expect(
        await hashOf('abc'.codeUnits),
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
      );
    });

    test('un archivo que no cabe en un trozo se lee entero', () async {
      // 300 000 «a»: varias lecturas seguidas, como un APK de verdad.
      expect(
        await hashOf(List.filled(300000, 0x61)),
        '12e1b9b179b29a4f7e5889b185d7ac71bff0ad1f49a7b391d0911b737a0f5381',
      );
    });

    test('el mismo contenido da siempre el mismo hash', () async {
      final first = await hashOf('APK de prueba de ComfyList'.codeUnits);
      final second = await hashOf('APK de prueba de ComfyList'.codeUnits);

      expect(first, second);
      expect(
        first,
        'a8f872c6dbaae56fb57f94dc74502da8a14eb2257e3731ebb7ab6aff256edd8b',
      );
    });

    test('un archivo que no existe no revienta sin más', () async {
      expect(
        () => sha256OfFile(File('${dir.path}/no-existe.bin')),
        throwsA(isA<FileSystemException>()),
      );
    });
  });
}
