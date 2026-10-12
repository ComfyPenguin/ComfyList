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

/// Override de depuración para probar el flujo de actualización sin publicar
/// nada: `--dart-define=APP_UPDATES_FAKE_INSTALLED_BUILD=230`.
const int _fakeInstalledBuild = int.fromEnvironment(
  'APP_UPDATES_FAKE_INSTALLED_BUILD',
);

/// Nº de build que está corriendo la app (`2026.10.11+231` → `231`): el mismo
/// número que Android guarda como `versionCode`. `null` si el paquete no lo
/// expone como número.
final installedBuildProvider = FutureProvider<int?>((ref) async {
  if (_fakeInstalledBuild > 0) return _fakeInstalledBuild;
  final info = await PackageInfo.fromPlatform();
  return int.tryParse(info.buildNumber);
});
