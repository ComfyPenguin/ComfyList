import 'package:flutter/services.dart';

import '../../../../shared/platform/apk_installer.dart';

enum ApkDownloadPhase { running, successful, failed }

class ApkDownloadStatus {
  const ApkDownloadStatus({
    required this.phase,
    this.received = 0,
    this.total = -1,
    this.reason = 0,
    this.path,
  });

  final ApkDownloadPhase phase;
  final int received;

  /// `-1` mientras el servidor no dice cuánto ocupa.
  final int total;

  /// `COLUMN_REASON` del DownloadManager: el código HTTP o un `ERROR_*`.
  final int reason;
  final String? path;
}

/// Descarga del APK por el DownloadManager de Android.
///
/// La baja el sistema y no la app: Android corta la red a las apps en segundo
/// plano y una descarga propia muere al salir de ComfyList. El puente nativo
/// vive en `MainActivity`.
class ApkDownloadManager {
  const ApkDownloadManager();

  static const MethodChannel _channel = MethodChannel(ApkInstaller.channelName);

  /// Encola la descarga, o devuelve la que ya estuviera en marcha para [url].
  Future<int> enqueue({
    required String url,
    required String fileName,
    required String title,
  }) async {
    final id = await _channel.invokeMethod<int>('enqueueDownload', {
      'url': url,
      'fileName': fileName,
      'title': title,
    });
    return id!;
  }

  Future<ApkDownloadStatus> status(int id) async {
    final map = await _channel.invokeMapMethod<String, Object?>(
      'downloadStatus',
      {'id': id},
    );
    return ApkDownloadStatus(
      phase: switch (map?['status']) {
        'successful' => ApkDownloadPhase.successful,
        'running' => ApkDownloadPhase.running,
        _ => ApkDownloadPhase.failed,
      },
      received: map?['received'] as int? ?? 0,
      total: map?['total'] as int? ?? -1,
      reason: map?['reason'] as int? ?? 0,
      path: map?['path'] as String?,
    );
  }

  /// Cancela la descarga y borra lo que hubiera bajado.
  Future<void> remove(int id) =>
      _channel.invokeMethod<void>('removeDownload', {'id': id});
}
