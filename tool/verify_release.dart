// Comprueba que lo publicado es lo que se ha compilado: el sha256 de cada
// archivo local contra el `digest` que GitHub devuelve de su asset. Es el mismo
// dato que compara la app antes de instalar, así que si aquí no cuadra, la
// actualización no llegaría a nadie.
// La usa .github/workflows/release.yml después de crear la release.
import 'dart:io';

import 'package:comfy_list/shared/core/files/file_checksum.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

/// GitHub calcula el `digest` al subir el asset: la primera lectura puede
/// pillarlo todavía sin él.
const Duration _digestRetryDelay = Duration(seconds: 3);
const int _digestAttempts = 5;

Future<void> main(List<String> args) async {
  final parsed = parseArgs(args);
  if (parsed == null) _usage();

  final repository = Platform.environment['GITHUB_REPOSITORY'];
  if (repository == null || repository.isEmpty) {
    stderr.writeln('Falta GITHUB_REPOSITORY; en el workflow lo pone GitHub.');
    exit(64);
  }

  final tag = parsed.tag;
  final localHashes = <String, String>{};
  for (final path in parsed.files) {
    final file = File(path);
    if (!file.existsSync()) {
      stderr.writeln('No existe $path.');
      exit(66);
    }
    localHashes[p.basename(path)] = await sha256OfFile(file);
  }

  final List<PublishedAsset> published;
  try {
    published = await _publishedAssets(
      repository: repository,
      tag: tag,
      token:
          Platform.environment['GH_TOKEN'] ??
          Platform.environment['GITHUB_TOKEN'],
      awaiting: localHashes.keys,
    );
  } on DioException catch (e) {
    stderr.writeln(
      e.response?.statusCode == 404
          ? 'GitHub no devuelve la release $tag.'
          : 'No se ha podido leer la release $tag: ${e.message ?? e.type}',
    );
    exit(1);
  }

  final problems = digestProblems(
    localHashes: localHashes,
    published: published,
  );
  if (problems.isNotEmpty) {
    stderr.writeln('Lo publicado no es lo compilado:');
    for (final problem in problems) {
      stderr.writeln('  - $problem');
    }
    stderr.writeln(
      'La release $tag ya está subida: bórrala y vuelve a publicarla antes de '
      'darla por buena.',
    );
    exit(1);
  }

  stdout.writeln('El sha256 de $tag coincide con lo compilado.');
}

/// El tag y los archivos que llegan por la línea de órdenes, o `null` si
/// faltan: aquí no hay subcomando, así que el tag va el primero.
({String tag, List<String> files})? parseArgs(List<String> args) {
  if (args.length < 2) return null;
  return (tag: args.first, files: args.sublist(1));
}

Never _usage() {
  stderr.writeln(
    'Uso: dart tool/verify_release.dart <tag> <archivo> [archivo…]\n'
    '  Compara el sha256 de cada archivo con el `digest` de su asset.',
  );
  exit(64);
}

/// Un asset publicado, con lo que la API dice de él.
class PublishedAsset {
  const PublishedAsset({required this.name, required this.digest});

  factory PublishedAsset.fromJson(Map<String, dynamic> json) => PublishedAsset(
    name: json['name'] as String? ?? '',
    digest: json['digest'] as String?,
  );

  final String name;

  /// `sha256:2151b604…`, o `null` si la release no lo trae.
  final String? digest;
}

/// Problemas que impiden dar la release por buena; vacío si todo cuadra.
///
/// Cada entrada de [localHashes] (nombre del asset → sha256 del archivo) tiene
/// que estar publicada con ese mismo hash.
List<String> digestProblems({
  required Map<String, String> localHashes,
  required List<PublishedAsset> published,
}) {
  final problems = <String>[];
  for (final entry in localHashes.entries) {
    final asset = _assetFor(published, entry.key);
    if (asset == null) {
      problems.add('${entry.key}: no está entre los assets de la release');
      continue;
    }
    final publishedHash = sha256FromDigest(asset.digest);
    if (publishedHash == null) {
      problems.add('${entry.key}: la release no publica un sha256 con el que comparar');
      continue;
    }
    final localHash = entry.value.toLowerCase();
    if (publishedHash != localHash) {
      problems.add('${entry.key}: publicado $publishedHash, compilado $localHash');
    }
  }
  return problems;
}

PublishedAsset? _assetFor(List<PublishedAsset> assets, String name) {
  for (final asset in assets) {
    if (asset.name == name) return asset;
  }
  return null;
}

Future<List<PublishedAsset>> _publishedAssets({
  required String repository,
  required String tag,
  required String? token,
  required Iterable<String> awaiting,
}) async {
  var assets = await _fetchAssets(repository: repository, tag: tag, token: token);
  for (var attempt = 1; attempt < _digestAttempts; attempt++) {
    final pending = awaiting.any(
      (name) => sha256FromDigest(_assetFor(assets, name)?.digest) == null,
    );
    if (!pending) break;
    await Future<void>.delayed(_digestRetryDelay);
    assets = await _fetchAssets(
      repository: repository,
      tag: tag,
      token: token,
    );
  }
  return assets;
}

Future<List<PublishedAsset>> _fetchAssets({
  required String repository,
  required String tag,
  required String? token,
}) async {
  final response = await Dio().get<Map<String, dynamic>>(
    'https://api.github.com/repos/$repository/releases/tags/$tag',
    options: Options(
      headers: {
        'Accept': 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28',
        'User-Agent': 'ComfyList',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
    ),
  );
  final assets = (response.data?['assets'] as List?) ?? const [];
  return [
    for (final asset in assets.whereType<Map<String, dynamic>>())
      PublishedAsset.fromJson(asset),
  ];
}
