import '../../../../shared/core/result/result.dart';
import '../entities/app_release.dart';

/// Contrato del comprobador de actualizaciones.
abstract class AppUpdatesRepository {
  /// Última release publicada. `Err` si no se puede leer o si el tag no se sabe
  /// interpretar (los tags anteriores al versionado por fecha).
  Future<Result<AppRelease>> latestRelease();

  /// Baja el APK de [release] y devuelve su ruta en el dispositivo.
  Future<Result<String>> downloadApk({
    required AppRelease release,
    void Function(int received, int total)? onProgress,
  });

  /// Vuelve a comprobar el APK de [path] contra el hash de [release] justo
  /// antes de instalarlo. Si ya no coincide, lo borra.
  Future<Result<void>> verifyApk({
    required AppRelease release,
    required String path,
  });
}
