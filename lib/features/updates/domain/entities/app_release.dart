import 'package:flutter/foundation.dart';

/// Versión publicada en GitHub Releases: lo que se compara con la instalada y
/// lo que se descarga.
@immutable
class AppRelease {
  const AppRelease({
    required this.version,
    required this.build,
    required this.notes,
    required this.downloadUrl,
    required this.assetName,
    this.publishedAt,
  });

  /// `2026.10.11` — la fecha del commit que publicó.
  final String version;

  /// Nº de commits de `main`: el mismo número que cierra la versión y que
  /// Android guarda como `versionCode`.
  final int build;

  /// Notas de la release, tal cual las escribió `tool/release.dart`.
  final String notes;

  final String downloadUrl;
  final String assetName;
  final DateTime? publishedAt;

  /// `2026.10.11.231`, como lo enseña el pie de Ajustes.
  String get label => '$version.$build';

  bool isNewerThan(int installedBuild) => build > installedBuild;

  /// Notas listas para pintar: `tool/release.dart` las escribe en Markdown
  /// (cabeceras `###`, viñetas `- **scope**: …`, enlaces y una línea final de
  /// «Cambios completos») y el diálogo las enseña como texto.
  ///
  /// Las cabeceras van sin prefijo y las viñetas empiezan por «• ».
  List<String> get noteLines {
    final lines = <String>[];
    for (final raw in notes.split('\n')) {
      var line = raw.trim();
      if (line.isEmpty || line.startsWith('---')) continue;
      if (line.startsWith('**Cambios completos**')) continue;
      if (line.startsWith('- ')) line = '• ${line.substring(2).trim()}';
      if (line.startsWith('### ')) line = line.substring(4).trim();
      line = _stripMarkdown(line);
      if (line.isNotEmpty) lines.add(line);
    }
    return lines;
  }

  /// Nº de build de un tag `v2026.10.11.231`. `null` si no sigue ese formato:
  /// el tag antiguo `v1.0.0` no lo hace.
  static int? buildFromTag(String tag) =>
      int.tryParse(_tagPattern.firstMatch(tag)?.group(2) ?? '');

  static String? versionFromTag(String tag) =>
      _tagPattern.firstMatch(tag)?.group(1);

  /// Nº de build del APK publicado (`comfylist-2026.10.11+231.apk`), para
  /// cuando el tag no lo lleva.
  static int? buildFromAssetName(String name) =>
      int.tryParse(_assetPattern.firstMatch(name)?.group(2) ?? '');

  static String? versionFromAssetName(String name) =>
      _assetPattern.firstMatch(name)?.group(1);

  static final RegExp _tagPattern = RegExp(r'^v(\d{4}\.\d{2}\.\d{2})\.(\d+)$');

  static final RegExp _assetPattern =
      RegExp(r'^comfylist-(\d{4}\.\d{2}\.\d{2})\+(\d+)\.apk$');

  static final RegExp _link = RegExp(r'\[([^\]]*)\]\([^)]*\)');

  static final RegExp _marker = RegExp(r'\*\*|__|`');

  static String _stripMarkdown(String line) => line
      .replaceAllMapped(_link, (match) => match.group(1) ?? '')
      .replaceAll(_marker, '')
      .trim();
}
