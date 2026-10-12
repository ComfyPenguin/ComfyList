import 'package:comfy_list/features/updates/domain/entities/app_release.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  group('parseo del tag', () {
    test('saca versión y build del formato que publica el workflow', () {
      expect(AppRelease.versionFromTag('v2026.10.11.231'), '2026.10.11');
      expect(AppRelease.buildFromTag('v2026.10.11.231'), 231);
    });

    test('el tag anterior al versionado por fecha no se interpreta', () {
      expect(AppRelease.versionFromTag('v1.0.0'), isNull);
      expect(AppRelease.buildFromTag('v1.0.0'), isNull);
    });

    test('un tag con otra forma tampoco', () {
      expect(AppRelease.buildFromTag('2026.10.11.231'), isNull);
      expect(AppRelease.buildFromTag('v2026.10.11'), isNull);
      expect(AppRelease.buildFromTag(''), isNull);
    });
  });

  group('parseo del nombre del APK', () {
    test('dice versión y build con el formato del asset', () {
      expect(
        AppRelease.versionFromAssetName('comfylist-2026.10.11+231.apk'),
        '2026.10.11',
      );
      expect(
        AppRelease.buildFromAssetName('comfylist-2026.10.11+231.apk'),
        231,
      );
    });

    test('el AAB o un nombre cualquiera no valen', () {
      expect(
        AppRelease.buildFromAssetName('comfylist-2026.10.11+231.aab'),
        isNull,
      );
      expect(AppRelease.buildFromAssetName('comfylist-2026.10.11.apk'), isNull);
    });
  });

  group('comparación con la instalada', () {
    test('solo es nueva si el build es mayor', () {
      final release = buildAppRelease(build: 231);

      expect(release.isNewerThan(230), isTrue);
      expect(release.isNewerThan(231), isFalse);
      expect(release.isNewerThan(232), isFalse);
    });

    test('la etiqueta es año.mes.dia.commits', () {
      expect(buildAppRelease().label, '2026.10.11.231');
    });
  });

  group('notas de la release', () {
    test('deja las viñetas y quita los marcadores de Markdown', () {
      final release = buildAppRelease(
        notes: '### Novedades\n'
            '\n'
            '- **listas**: se pueden reordenar\n'
            '- arreglos varios\n'
            '\n'
            '---\n'
            '\n'
            '**Cambios completos**: [`v1...v2`](https://github.com/x/y/compare)\n',
      );

      expect(release.noteLines, [
        'Novedades',
        '• listas: se pueden reordenar',
        '• arreglos varios',
      ]);
    });

    test('con el cuerpo tal como lo publica GitHub', () {
      // Copiado de la respuesta real de `/releases/latest`.
      final release = buildAppRelease(
        notes: '### Novedades\n'
            '\n'
            '- **settings**: mostrar la versión instalada en el pie de Ajustes\n'
            '\n'
            '---\n'
            '\n'
            '**Cambios completos**: [`v1.0.0...v2026.10.11.231`]'
            '(https://github.com/ComfyPenguin/ComfyList/compare/v1.0.0...v2026.10.11.231)\n',
      );

      expect(release.noteLines, [
        'Novedades',
        '• settings: mostrar la versión instalada en el pie de Ajustes',
      ]);
    });

    test('sin notas no hay nada que pintar', () {
      expect(buildAppRelease().noteLines, isEmpty);
    });
  });
}
