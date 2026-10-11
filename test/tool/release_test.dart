import 'package:flutter_test/flutter_test.dart';

import '../../tool/release.dart';

void main() {
  group('parseCommits', () {
    test('separa asunto y cuerpo, y tolera el sobrante del final', () {
      final commits = parseCommits('feat(a): uno\x1fcuerpo\x1e\r\n');

      expect(commits, hasLength(1));
      expect(commits.single.subject, 'feat(a): uno');
      expect(commits.single.body, 'cuerpo');
    });

    test('sin cuerpo deja el body vacío', () {
      final commits = parseCommits('docs: algo\x1f\x1e');

      expect(commits.single.body, '');
    });
  });

  group('bumpForCommits', () {
    test('un breaking change sube major aunque haya feats', () {
      expect(
        bumpForCommits(parseCommits('feat: a\x1f\x1efeat(api)!: b\x1f\x1e')),
        'major',
      );
    });

    test('BREAKING CHANGE en el cuerpo también sube major', () {
      expect(
        bumpForCommits(parseCommits('fix: a\x1fBREAKING CHANGE: rompe\x1e')),
        'major',
      );
    });

    test('feat sube minor', () {
      expect(
        bumpForCommits(parseCommits('feat: a\x1f\x1efix: b\x1f\x1e')),
        'minor',
      );
    });

    test('fix y perf suben patch', () {
      expect(bumpForCommits(parseCommits('fix: a\x1f\x1e')), 'patch');
      expect(bumpForCommits(parseCommits('perf: a\x1f\x1e')), 'patch');
    });

    test('docs, chore o refactor no publican', () {
      expect(
        bumpForCommits(
          parseCommits('docs: a\x1f\x1echore: b\x1f\x1erefactor: c\x1f\x1e'),
        ),
        'none',
      );
    });
  });

  group('tagFor', () {
    test('junta la fecha del commit y su número de commits', () {
      expect(tagFor('2026.10.11', '221'), 'v2026.10.11.221');
    });
  });

  group('withVersion', () {
    test('reescribe la línea version y conserva el resto', () {
      const pubspec =
          'name: comfy_list\r\nversion: 1.0.0+1\r\ndescription: hola\r\n';

      final updated = withVersion(pubspec, '2026.10.11', '221');

      expect(updated, contains('version: 2026.10.11+221\r\n'));
      expect(updated, contains('name: comfy_list\r\n'));
      expect(pubspecVersion(updated!), '2026.10.11');
    });

    test('devuelve null si no hay línea version', () {
      expect(withVersion('name: comfy_list\n', '1.0.0', '1'), isNull);
    });
  });

  group('formatNotes', () {
    final commits = parseCommits(
      'feat(papelera): agrupar borrados\x1f\x1e'
      'fix: corregir cierre\x1f\x1e'
      'docs: guía\x1f\x1e',
    );

    test('agrupa por tipo y omite lo que no se publica', () {
      final notes = formatNotes(commits: commits, tag: 'v1.1.0');

      expect(notes, contains('### Novedades'));
      expect(notes, contains('- **papelera**: agrupar borrados'));
      expect(notes, contains('### Correcciones'));
      expect(notes, contains('- corregir cierre'));
      expect(notes, isNot(contains('guía')));
      expect(notes, isNot(contains('Cambios completos')));
    });

    test('añade el enlace de comparación cuando hay tag anterior', () {
      final notes = formatNotes(
        commits: commits,
        tag: 'v1.1.0',
        previousTag: 'v1.0.0',
        repository: 'ComfyPenguin/ComfyList',
      );

      expect(
        notes,
        contains(
          '**Cambios completos**: [`v1.0.0...v1.1.0`]'
          '(https://github.com/ComfyPenguin/ComfyList/compare/v1.0.0...v1.1.0)',
        ),
      );
    });
  });
}
