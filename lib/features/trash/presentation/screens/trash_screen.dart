import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/core/text/date_format.dart';
import '../../../../shared/core/theme/app_radius.dart';
import '../../../../shared/core/theme/app_spacing.dart';
import '../../../../shared/core/theme/app_stroke.dart';
import '../../../../shared/core/theme/app_theme.dart';
import '../../../../shared/core/theme/app_typography.dart';
import '../../../../shared/ui/dialogs/confirm_action_dialog.dart';
import '../../../../shared/ui/toast/app_toast.dart';
import '../../domain/entities/trash_entry.dart';
import '../providers/trash_provider.dart';
import '../providers/trash_restore.dart';
import '../providers/trash_state.dart';
import '../widgets/trash_empty_state.dart';

/// Pantalla de la papelera: lo borrado en la app, guardado solo en este
/// dispositivo. Vive dentro del [AppShell], que pone el título y la flecha
/// atrás en su TopBar.
class TrashScreen extends ConsumerStatefulWidget {
  const TrashScreen({super.key});

  @override
  ConsumerState<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends ConsumerState<TrashScreen> {
  /// Mientras algo vuelve a Firestore no se aceptan más toques.
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(trashProvider);
    final entries = switch (state) {
      TrashData(:final entries) => entries,
      _ => const <TrashEntry>[],
    };

    // El TopBar del shell se superpone al contenido: reservamos su altura
    // (iconButton + padding del AppBar) más un margen hasta la primera fila.
    final topOffset = MediaQuery.paddingOf(context).top + 56 + AppSpacing.md;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        topOffset,
        AppSpacing.lg,
        AppSpacing.section,
      ),
      children: [
        if (state is TrashError) ...[
          const _LoadErrorBanner(),
          const SizedBox(height: AppSpacing.md),
        ],
        if (state is TrashData && entries.isEmpty) const TrashEmptyState(),
        if (entries.isNotEmpty) ...[
          _Header(
            count: entries.length,
            onEmpty: _busy ? null : _emptyTrash,
          ),
          const SizedBox(height: AppSpacing.md),
          for (final (index, entry) in entries.indexed) ...[
            if (index > 0) const SizedBox(height: AppSpacing.joined),
            _TrashTile(
              entry: entry,
              isFirst: index == 0,
              isLast: index == entries.length - 1,
              enabled: !_busy,
              onRestore: () => _restore(entries, entry),
            ),
          ],
        ],
      ],
    );
  }

  /// Devuelve [entry] a Firestore y lo saca de la papelera. Una lista vuelve
  /// con sus tareas: se borraron juntas y comparten grupo.
  Future<void> _restore(List<TrashEntry> entries, TrashEntry entry) async {
    if (_busy) return;
    setState(() => _busy = true);

    final group = entries
        .where((candidate) => candidate.groupId == entry.groupId)
        .toList(growable: false);

    final restored = await ref.read(trashRestorerProvider).restoreGroup(group);
    if (restored) {
      await ref.read(trashProvider.notifier).remove(group);
    } else if (mounted) {
      AppToast.show(context, AppToast.restoreFailed);
    }

    if (mounted) setState(() => _busy = false);
  }

  Future<void> _emptyTrash() async {
    final confirmed = await ConfirmActionDialog.show(
      context,
      title: '¿Vaciar la papelera?',
      message: 'Se perderán todos los borrados y ya no habrá forma de '
          'recuperarlos.',
      confirmLabel: 'Vaciar',
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    await ref.read(trashProvider.notifier).empty();
    if (mounted) AppToast.show(context, AppToast.trashEmptied);
  }
}

/// Cuántos borrados hay y el atajo para tirarlos todos.
class _Header extends StatelessWidget {
  const _Header({required this.count, required this.onEmpty});

  final int count;
  final VoidCallback? onEmpty;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Expanded(
          child: Text(
            count == 1 ? '1 elemento guardado' : '$count elementos guardados',
            style: AppTypography.bodySm.copyWith(color: colors.muted),
          ),
        ),
        TextButton.icon(
          onPressed: onEmpty,
          icon: const Icon(Icons.delete_sweep_outlined, size: 18),
          label: const Text('Vaciar'),
        ),
      ],
    );
  }
}

/// Fila de la papelera con el aspecto de las tiles de las listas.
class _TrashTile extends StatelessWidget {
  const _TrashTile({
    required this.entry,
    required this.isFirst,
    required this.isLast,
    required this.enabled,
    required this.onRestore,
  });

  final TrashEntry entry;
  final bool isFirst;
  final bool isLast;
  final bool enabled;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final label = entry.label.isEmpty ? _kindLabel(entry.kind) : entry.label;

    return Material(
      color: colors.canvas,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.joinedGroup(isFirst: isFirst, isLast: isLast),
        side: BorderSide(color: colors.cardBorder, width: AppStroke.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
        ),
        child: Row(
          children: [
            Icon(_kindIcon(entry.kind), size: 20, color: colors.body),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMdStrong.copyWith(
                      color: colors.ink,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    '${_kindLabel(entry.kind)} · ${_whenText(entry.deletedAt)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySm.copyWith(color: colors.body),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            TextButton.icon(
              onPressed: enabled ? onRestore : null,
              icon: const Icon(Icons.undo_rounded, size: 18),
              label: const Text('Restaurar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadErrorBanner extends StatelessWidget {
  const _LoadErrorBanner();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Icon(Icons.error_outline_rounded, size: 20, color: colors.error),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            'No se ha podido leer la papelera.',
            style: AppTypography.bodySm.copyWith(color: colors.ink),
          ),
        ),
      ],
    );
  }
}

String _kindLabel(TrashKind kind) => switch (kind) {
      TrashKind.list => 'Lista',
      TrashKind.todo => 'Tarea',
      TrashKind.appointment => 'Cita',
    };

IconData _kindIcon(TrashKind kind) => switch (kind) {
      TrashKind.list => Icons.inbox_rounded,
      TrashKind.todo => Icons.checklist_rounded,
      TrashKind.appointment => Icons.event_rounded,
    };

/// «hoy», «ayer» o la fecha: en una papelera lo que importa es cuándo se borró.
String _whenText(DateTime deletedAt) {
  final local = deletedAt.toLocal();
  final now = DateTime.now();
  final days = DateTime(now.year, now.month, now.day)
      .difference(DateTime(local.year, local.month, local.day))
      .inDays;
  return switch (days) {
    0 => 'hoy',
    1 => 'ayer',
    _ => formatShortDate(local),
  };
}
