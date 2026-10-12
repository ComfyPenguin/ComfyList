import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/core/theme/app_theme.dart';
import '../../../updates/presentation/providers/app_updates_provider.dart';
import '../../../updates/presentation/providers/app_updates_state.dart';
import '../../../updates/presentation/widgets/update_available_dialog.dart';
import 'settings_tile.dart';

/// Fila que comprueba si hay versión nueva, la baja y lanza el instalador del
/// sistema.
///
/// Solo se monta donde el comprobador tiene sentido
/// ([updateCheckSupportedProvider]): las releases publican únicamente Android.
class UpdateCheckTile extends ConsumerWidget {
  const UpdateCheckTile({super.key, this.isFirst = true, this.isLast = true});

  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final state = ref.watch(appUpdatesProvider);
    final notifier = ref.read(appUpdatesProvider.notifier);

    final chevron = Icon(Icons.chevron_right_rounded, color: colors.muted);

    final (description, trailing, onTap) = switch (state) {
      AppUpdatesInitial() => (
        'Comprueba si hay una versión nueva para instalar.',
        chevron,
        () => notifier.check(),
      ),
      AppUpdatesChecking() => (
        'Comprobando…',
        const SettingsTileSpinner(),
        null,
      ),
      AppUpdatesUpToDate() => (
        'Estás al día.',
        Icon(Icons.check_rounded, size: 20, color: colors.primary),
        () => notifier.check(),
      ),
      AppUpdatesAvailable(:final release) => (
        'Hay una versión nueva: ${release.label}.',
        chevron,
        () => UpdateAvailableDialog.show(context, release),
      ),
      AppUpdatesDownloading(:final progress) => (
        'Descargando… ${(progress * 100).round()} %',
        const SettingsTileSpinner(),
        null,
      ),
      AppUpdatesReady() => (
        'Lista para instalar.',
        Icon(Icons.download_done_rounded, size: 20, color: colors.primary),
        notifier.install,
      ),
      // Un fallo al bajar el APK reintenta la descarga; si no llegó a haber
      // versión, vuelve a preguntar a GitHub.
      AppUpdatesFailed(:final failure, :final release) => (
        failure.message,
        TextButton(
          onPressed: release == null
              ? () => notifier.check()
              : () => notifier.download(release),
          child: const Text('Reintentar'),
        ),
        null,
      ),
    };

    return SettingsTile(
      icon: Icons.system_update_alt_rounded,
      title: 'Buscar actualizaciones',
      description: description,
      trailing: trailing,
      onTap: onTap,
      isFirst: isFirst,
      isLast: isLast,
    );
  }
}
