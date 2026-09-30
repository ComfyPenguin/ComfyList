import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/core/text/date_format.dart';
import '../../../../shared/core/theme/app_radius.dart';
import '../../../../shared/core/theme/app_spacing.dart';
import '../../../../shared/core/theme/app_stroke.dart';
import '../../../../shared/core/theme/app_theme.dart';
import '../../../../shared/core/theme/app_typography.dart';
import '../../../../shared/ui/animations/unfold_down.dart';
import '../../../../shared/ui/dialogs/confirm_action_dialog.dart';
import '../../../../shared/ui/toast/app_toast.dart';
import '../../domain/entities/trash_entry.dart';
import '../../domain/entities/trash_group.dart';
import '../providers/trash_provider.dart';
import '../providers/trash_restore.dart';
import '../providers/trash_state.dart';
import '../widgets/trash_empty_state.dart';

/// Pantalla de la papelera: lo borrado en la app, guardado en la cuenta del
/// usuario. Vive dentro del [AppShell], que pone el título y la flecha atrás
/// en su TopBar.
class TrashScreen extends ConsumerStatefulWidget {
  const TrashScreen({super.key});

  @override
  ConsumerState<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends ConsumerState<TrashScreen> {
  /// Mientras algo vuelve a Firestore no se aceptan más toques.
  bool _busy = false;

  /// Borrados con lo de dentro a la vista. Es solo para mirar: se devuelve el
  /// borrado entero, con sus tareas, se despliegue o no.
  final Set<String> _expanded = {};

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(trashProvider);
    // Una fila por borrado: una lista con sus tareas es una sola cosa, aunque
    // por dentro sean varios documentos.
    final groups = switch (state) {
      TrashData(:final entries) => TrashGroup.partition(entries),
      _ => const <TrashGroup>[],
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
        if (state is TrashData && groups.isEmpty) const TrashEmptyState(),
        if (groups.isNotEmpty) ...[
          _Header(
            count: groups.length,
            onEmpty: _busy ? null : _emptyTrash,
          ),
          const SizedBox(height: AppSpacing.md),
          for (final (index, group) in groups.indexed) ...[
            if (index > 0) const SizedBox(height: AppSpacing.joined),
            _TrashTile(
              group: group,
              isFirst: index == 0,
              isLast: index == groups.length - 1,
              enabled: !_busy,
              expanded: _expanded.contains(group.groupId),
              onToggleExpanded: () => _toggleExpanded(group.groupId),
              onRestore: () => _restore(group),
            ),
          ],
        ],
      ],
    );
  }

  void _toggleExpanded(String groupId) {
    setState(() {
      if (!_expanded.remove(groupId)) _expanded.add(groupId);
    });
  }

  /// Devuelve [group] a Firestore y lo saca de la papelera. Una lista vuelve
  /// con sus tareas: se borraron juntas y comparten grupo.
  Future<void> _restore(TrashGroup group) async {
    if (_busy) return;
    setState(() => _busy = true);

    final restored = await ref.read(trashRestorerProvider).restoreGroup(group);
    if (restored) {
      await ref.read(trashProvider.notifier).remove(group.entries);
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
            count == 1 ? '1 borrado guardado' : '$count borrados guardados',
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

/// Fila de la papelera con el aspecto de las tiles de las listas. Un borrado
/// con contenido lleva su desplegable: lo de dentro se mira, no se devuelve
/// suelto.
class _TrashTile extends StatelessWidget {
  const _TrashTile({
    required this.group,
    required this.isFirst,
    required this.isLast,
    required this.enabled,
    required this.expanded,
    required this.onToggleExpanded,
    required this.onRestore,
  });

  final TrashGroup group;
  final bool isFirst;
  final bool isLast;
  final bool enabled;
  final bool expanded;
  final VoidCallback onToggleExpanded;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final header = group.header;
    final contents = group.contents;
    final label = header.label.isEmpty ? _kindLabel(header.kind) : header.label;

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(_kindIcon(header.kind), size: 20, color: colors.body),
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
                        [
                          _kindLabel(header.kind),
                          _whenText(header.deletedAt),
                          if (contents.isNotEmpty) _contentsCount(contents),
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySm.copyWith(
                          color: colors.body,
                        ),
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
            if (contents.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: enabled ? onToggleExpanded : null,
                  icon: Icon(
                    expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 18,
                  ),
                  label: Text(
                    expanded ? 'Ocultar' : _contentsToggle(contents.length),
                  ),
                ),
              ),
              UnfoldDown(
                open: expanded,
                child: Padding(
                  // Sangradas: lo de dentro de la lista no está al mismo nivel
                  // que ella.
                  padding: const EdgeInsets.only(
                    left: AppSpacing.xl,
                    right: AppSpacing.sm,
                    bottom: AppSpacing.xs,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final (index, entry) in contents.indexed) ...[
                        if (index > 0) const SizedBox(height: AppSpacing.sm),
                        _InsideRow(entry: entry),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Lo que se llevó el borrado por dentro. Solo se lee: vuelve con la lista.
class _InsideRow extends StatelessWidget {
  const _InsideRow({required this.entry});

  final TrashEntry entry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Icon(_kindIcon(entry.kind), size: 16, color: colors.muted),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            entry.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySm.copyWith(color: colors.body),
          ),
        ),
      ],
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

/// «3 tareas»: lo que la lista se llevó por dentro.
String _contentsCount(List<TrashEntry> contents) =>
    contents.length == 1 ? '1 tarea' : '${contents.length} tareas';

String _contentsToggle(int count) =>
    count == 1 ? 'Ver la tarea' : 'Ver las $count tareas';

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
