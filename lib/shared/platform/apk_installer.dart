import 'package:flutter/services.dart';

import '../core/failures/failure.dart';
import '../core/result/result.dart';

/// Abre el instalador de Android con un APK ya descargado.
///
/// Android no instala nada en silencio: esto lanza el diálogo del sistema y el
/// toque final lo da quien usa la app. El puente nativo vive en `MainActivity`.
class ApkInstaller {
  const ApkInstaller();

  /// Nombre del canal que implementa `MainActivity` en Android.
  static const String channelName = 'comfy_list/updates';

  static const MethodChannel _channel = MethodChannel(channelName);

  Future<Result<void>> install(String path) async {
    try {
      await _channel.invokeMethod<void>('installApk', <String, String>{
        'path': path,
      });
      return const Ok<void>(null);
    } on PlatformException catch (e) {
      return Err(UnknownFailure(_messageFor(e)));
    } on MissingPluginException {
      return const Err(
        UnknownFailure('Esta plataforma no sabe instalar la actualización.'),
      );
    }
  }

  static String _messageFor(PlatformException e) => switch (e.code) {
    'unknownSources' =>
      'Da permiso a ComfyList para instalar apps en el ajuste que se ha '
          'abierto y vuelve a intentarlo.',
    'noActivity' => 'No se ha podido abrir el instalador de Android.',
    'noFile' => 'El APK descargado ya no está disponible. Vuelve a intentarlo.',
    _ => e.message ?? 'No se ha podido abrir el instalador.',
  };
}
