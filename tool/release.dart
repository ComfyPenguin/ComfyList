// Herramienta de release: calcula la próxima versión a partir de los
// conventional commits, la aplica a pubspec.yaml y genera las notas.
// La usa .github/workflows/release.yml.
import 'dart:io';

void main(List<String> args) {
  if (args.isEmpty) _usage();

  switch (args.first) {
    case 'plan':
      _plan();
    case 'apply':
      _apply(args);
    case 'notes':
      _notes(args);
    default:
      _usage();
  }
}

void _usage() {
  stderr.writeln(
    'Uso: dart tool/release.dart <plan|apply|notes> [argumentos]\n'
    '  plan                        Calcula la próxima versión (clave=valor)\n'
    '  apply <versión> <build>     Escribe la versión en pubspec.yaml\n'
    '  notes <tag anterior> <tag>  Genera las notas de release en Markdown',
  );
  exit(64);
}

/// Plan calculado desde el último tag y los commits de `HEAD`.
void _plan() {
  final current = pubspecVersion(File('pubspec.yaml').readAsStringSync());
  if (current == null) {
    stderr.writeln('No se pudo leer la versión actual de pubspec.yaml');
    exit(65);
  }

  final previousTag = _lastTag();
  final bump = previousTag == null
      ? 'initial'
      : bumpForCommits(_commitsSince(previousTag));
  final version = bump == 'none' ? current : nextVersion(current, bump);

  stdout
    ..writeln('bump=$bump')
    ..writeln('version=$version')
    ..writeln('build=${_git(['rev-list', '--count', 'HEAD'])}')
    ..writeln('tag=v$version')
    ..writeln('previous_tag=${previousTag ?? ''}');
}

/// Escribe `<versión>+<build>` en la línea `version:` de pubspec.yaml.
void _apply(List<String> args) {
  if (args.length < 3) _usage();

  final file = File('pubspec.yaml');
  final updated = withVersion(file.readAsStringSync(), args[1], args[2]);
  if (updated == null) {
    stderr.writeln('No se encontró la línea `version:` en pubspec.yaml');
    exit(65);
  }
  file.writeAsStringSync(updated);
}

/// Imprime en stdout las notas de release para el rango `tag anterior..HEAD`.
void _notes(List<String> args) {
  if (args.length < 3) _usage();

  final previousTag = args[1].isEmpty ? null : args[1];
  stdout.write(
    formatNotes(
      commits: _commitsSince(previousTag),
      tag: args[2],
      previousTag: previousTag,
      repository: Platform.environment['GITHUB_REPOSITORY'],
    ),
  );
}

class Commit {
  Commit(this.subject, [this.body = '']);

  final String subject;
  final String body;

  late final RegExpMatch? _header = RegExp(
    r'^([a-zA-Z]+)(?:\(([^)]*)\))?(!)?:',
  ).firstMatch(subject);

  String? get type => _header?.group(1)?.toLowerCase();

  String? get scope => _header?.group(2);

  bool get isBreaking =>
      _header?.group(3) == '!' ||
      body.contains('BREAKING CHANGE:') ||
      body.contains('BREAKING-CHANGE:');

  /// El asunto sin `tipo(scope)!:` y con el scope en negrita.
  String get message {
    final header = _header;
    if (header == null) return subject;
    final rest = subject.substring(header.end).trim();
    final scope = this.scope;
    return scope == null ? rest : '**$scope**: $rest';
  }
}

/// Parsea la salida de `git log --pretty=format:%s%x1f%b%x1e`.
List<Commit> parseCommits(String raw) {
  final commits = <Commit>[];
  for (final record in raw.split('\x1e')) {
    final fields = record.trim().split('\x1f');
    if (fields.first.isEmpty) continue;
    commits.add(
      Commit(fields.first.trim(), fields.length > 1 ? fields[1].trim() : ''),
    );
  }
  return commits;
}

/// El mayor bump que piden los commits: major, minor, patch o none.
String bumpForCommits(List<Commit> commits) {
  if (commits.any((commit) => commit.isBreaking)) return 'major';
  if (commits.any((commit) => commit.type == 'feat')) return 'minor';
  if (commits.any((commit) => commit.type == 'fix' || commit.type == 'perf')) {
    return 'patch';
  }
  return 'none';
}

String nextVersion(String current, String bump) {
  final parts = current.split('.').map(int.parse).toList();
  return switch (bump) {
    'major' => '${parts[0] + 1}.0.0',
    'minor' => '${parts[0]}.${parts[1] + 1}.0',
    'patch' => '${parts[0]}.${parts[1]}.${parts[2] + 1}',
    _ => current,
  };
}

final _versionLine = RegExp(
  r'^version: *([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+)',
  multiLine: true,
);

String? pubspecVersion(String pubspec) =>
    _versionLine.firstMatch(pubspec)?.group(1);

/// Devuelve el pubspec con la versión cambiada, o null si no hay línea
/// `version:` que reemplazar.
String? withVersion(String pubspec, String version, String build) {
  if (!_versionLine.hasMatch(pubspec)) return null;
  return pubspec.replaceFirst(_versionLine, 'version: $version+$build');
}

/// Notas en Markdown agrupadas por tipo de cambio.
String formatNotes({
  required List<Commit> commits,
  required String tag,
  String? previousTag,
  String? repository,
}) {
  final sections = <String, Iterable<Commit>>{
    'Cambios incompatibles': commits.where((commit) => commit.isBreaking),
    'Novedades': commits.where(
      (commit) => !commit.isBreaking && commit.type == 'feat',
    ),
    'Correcciones': commits.where(
      (commit) => !commit.isBreaking && commit.type == 'fix',
    ),
    'Rendimiento': commits.where(
      (commit) => !commit.isBreaking && commit.type == 'perf',
    ),
  };

  final buffer = StringBuffer();
  for (final section in sections.entries) {
    if (section.value.isEmpty) continue;
    buffer.writeln('### ${section.key}');
    buffer.writeln();
    for (final commit in section.value) {
      buffer.writeln('- ${commit.message}');
    }
    buffer.writeln();
  }

  var notes = buffer.toString().trimRight();
  if (notes.isEmpty) notes = 'Sin cambios destacables.';

  if (repository != null && previousTag != null) {
    notes +=
        '\n\n---\n\n**Cambios completos**: '
        '[`$previousTag...$tag`](https://github.com/$repository/compare/$previousTag...$tag)';
  }

  return '$notes\n';
}

List<Commit> _commitsSince(String? tag) => parseCommits(
  _git([
    'log',
    '--no-merges',
    '--pretty=format:%s%x1f%b%x1e',
    tag == null ? 'HEAD' : '$tag..HEAD',
  ]),
);

String? _lastTag() {
  final result = Process.runSync('git', [
    'describe',
    '--tags',
    '--abbrev=0',
    '--match',
    'v*',
  ]);
  if (result.exitCode != 0) return null;
  final tag = (result.stdout as String).trim();
  return tag.isEmpty ? null : tag;
}

String _git(List<String> args) {
  final result = Process.runSync('git', args);
  if (result.exitCode != 0) {
    stderr.writeln('git ${args.join(' ')} falló: ${result.stderr}');
    exit(65);
  }
  return (result.stdout as String).trim();
}
