import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/core/theme/app_radius.dart';
import '../../../../shared/core/theme/app_spacing.dart';
import '../../../../shared/core/theme/app_stroke.dart';
import '../../../../shared/core/theme/app_theme.dart';
import '../../../../shared/core/theme/app_typography.dart';
import '../../../../shared/ui/buttons/primary_button.dart';
import '../../domain/entities/app_release.dart';
import '../providers/app_updates_provider.dart';
import '../providers/app_updates_state.dart';

/// Aviso de versión nueva: las notas de la release y el botón que baja el APK y
/// abre el instalador del sistema.
///
/// El progreso vive en el provider, así que el diálogo se va actualizando solo
/// mientras descarga y cambia a «Instalar» cuando el APK ya está en el móvil.
class UpdateAvailableDialog extends ConsumerWidget {
  const UpdateAvailableDialog({super.key, required this.release});

  final AppRelease release;

  static Future<void> show(BuildContext context, AppRelease release) {
    return showDialog<void>(
      context: context,
      builder: (_) => UpdateAvailableDialog(release: release),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final state = ref.watch(appUpdatesProvider);
    // El estado solo vale si habla de esta versión: si mientras el diálogo está
    // abierto se comprueba otra, aquí se empieza de cero.
    final mine = state.release?.build == release.build ? state : null;
    final notifier = ref.read(appUpdatesProvider.notifier);

    final progress = switch (mine) {
      AppUpdatesDownloading(:final progress) => progress,
      _ => null,
    };
    final failure = switch (mine) {
      AppUpdatesFailed(:final failure) => failure,
      _ => null,
    };

    final (label, icon, onPressed) = switch (mine) {
      AppUpdatesDownloading() => ('Descargando', null, null),
      AppUpdatesReady() => (
        'Instalar',
        Icons.download_done_rounded,
        notifier.install,
      ),
      AppUpdatesFailed() => ('Reintentar', null, () => notifier.download(release)),
      _ => (
        'Actualizar',
        Icons.system_update_alt_rounded,
        () => notifier.download(release),
      ),
    };

    final notes = release.noteLines;

    return Dialog(
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.brDialog),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: colors.canvas,
          borderRadius: AppRadius.brDialog,
          border: Border.all(
            color: colors.cardBorder,
            width: AppStroke.hairline,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Hay una versión nueva',
                style: AppTypography.displaySm.copyWith(color: colors.ink),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'ComfyList ${release.label}',
                style: AppTypography.bodyMdStrong.copyWith(
                  color: colors.primary,
                ),
                textAlign: TextAlign.center,
              ),
              if (notes.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                // Las notas de una release no dan para llenar la pantalla: con
                // tope y scroll, un diálogo largo no se sale del móvil.
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final line in notes) _NoteLine(line: line),
                      ],
                    ),
                  ),
                ),
              ],
              if (progress != null) ...[
                const SizedBox(height: AppSpacing.lg),
                LinearProgressIndicator(
                  value: progress <= 0 ? null : progress,
                  valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                  backgroundColor: colors.muted,
                  minHeight: 6,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Descargando… ${(progress * 100).round()} %',
                  style: AppTypography.caption.copyWith(color: colors.body),
                  textAlign: TextAlign.center,
                ),
              ],
              if (failure != null) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  failure.message,
                  style: AppTypography.bodySm.copyWith(color: colors.error),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: label,
                icon: icon,
                isLoading: progress != null,
                onPressed: onPressed,
                expand: true,
              ),
              const SizedBox(height: AppSpacing.xs),
              TextButton(
                onPressed: () {
                  notifier.skip(release);
                  Navigator.of(context).pop();
                },
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Ahora no',
                  style: AppTypography.bodyMd.copyWith(color: colors.body),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Línea de las notas: las viñetas van sangradas y las cabeceras de sección
/// destacan sobre ellas.
class _NoteLine extends StatelessWidget {
  const _NoteLine({required this.line});

  final String line;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isBullet = line.startsWith('• ');

    return Padding(
      padding: EdgeInsets.only(
        left: isBullet ? AppSpacing.md : 0,
        bottom: AppSpacing.xxs,
      ),
      child: Text(
        line,
        style: isBullet
            ? AppTypography.bodySm.copyWith(color: colors.body)
            : AppTypography.bodySmStrong.copyWith(color: colors.ink),
      ),
    );
  }
}
