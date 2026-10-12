import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Versión del paquete que está corriendo, como `2026.10.11.221`.
///
/// Sale del paquete instalado, así que en un build local enseña la que tenga
/// el pubspec en ese momento y no la última publicada.
final appVersionLabelProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return '${info.version}.${info.buildNumber}';
});
