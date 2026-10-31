import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/core/theme/app_radius.dart';
import '../../../../shared/core/theme/app_spacing.dart';
import '../../../../shared/core/theme/app_theme.dart';
import '../../../../shared/core/theme/app_typography.dart';
import '../../../../shared/ui/buttons/primary_button.dart';
import '../../../../shared/ui/completed_status_indicator.dart';
import '../../../../shared/ui/pending_status_indicator.dart';
import '../../domain/entities/todo.dart';
import '../providers/todos_provider.dart';
import '../providers/todos_state.dart';

/// Bottom sheet que muestra los detalles de una tarea (solo lectura).
///
/// Comparte la composición visual del detalle de citas: título y estado en la
/// cabecera, descripción sobre una superficie elevada y una acción principal
/// de edición al final.
class TodoDetailSheet extends ConsumerWidget {
  const TodoDetailSheet({
    super.key,
    required this.listId,
    required this.todoId,
    required this.onEdit,
  });

  final String listId;
  final String todoId;

  /// Callback que cierra el sheet y navega a la pantalla de edición.
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(todosProvider(listId));
    final colors = context.colors;

    // El 85 % es un tope, no la altura de la hoja: quien la mide es el contenido,
    // así que las ramas sin contenido no lo llenan (`heightFactor: 1`).
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: switch (state) {
        TodosInitial() || TodosLoading() => const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
          child: Center(
            heightFactor: 1,
            child: CircularProgressIndicator(),
          ),
        ),
        TodosError(:final failure) => Padding(
          padding: const EdgeInsets.all(AppSpacing.xxxl),
          child: Center(
            heightFactor: 1,
            child: Text(
              failure.message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMd.copyWith(color: colors.body),
            ),
          ),
        ),
        TodosData(:final items) => _buildContent(context, items, colors),
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<Todo> items,
    AppColors colors,
  ) {
    final todo = items.where((t) => t.id == todoId).firstOrNull;

    // Si la tarea fue eliminada mientras el sheet estaba abierto.
    if (todo == null) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Center(
          heightFactor: 1,
          child: Text(
            'Tarea no encontrada.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMd.copyWith(color: colors.body),
          ),
        ),
      );
    }

    final isDark = colors.isDarkCanvas;
    final datesMatch = todo.createdAt.isAtSameMomentAs(todo.updatedAt);
    final metadataLabel = datesMatch ? 'Creada' : 'Última edición';
    final metadataDate = datesMatch ? todo.createdAt : todo.updatedAt;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera: título y estado, igual que en el detalle de citas.
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xxxl,
              AppSpacing.sm,
              AppSpacing.xxxl,
              0,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    todo.title,
                    style: AppTypography.displayMd.copyWith(
                      color: colors.ink,
                      decoration: todo.isDone
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                todo.isDone
                    ? const CompletedStatusIndicator()
                    : const PendingStatusIndicator(),
              ],
            ),
          ),
          if (todo.description != null && todo.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xxxl,
                AppSpacing.xxxl,
                AppSpacing.xxxl,
                0,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: isDark ? colors.surfacePressed : colors.canvasSoft,
                  borderRadius: AppRadius.brXl,
                  boxShadow: isDark
                      ? [
                          BoxShadow(
                            color: colors.ink.withValues(alpha: 0.20),
                            blurRadius: 12,
                            spreadRadius: 1,
                          ),
                          BoxShadow(
                            color: colors.ink.withValues(alpha: 0.12),
                            blurRadius: 28,
                            spreadRadius: 2,
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: colors.shadowDark.withValues(alpha: 0.30),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                          BoxShadow(
                            color: colors.shadowDark.withValues(alpha: 0.18),
                            blurRadius: 28,
                            offset: Offset.zero,
                          ),
                        ],
                ),
                child: Text(
                  todo.description!,
                  style: AppTypography.bodyMd.copyWith(color: colors.body),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xxxl,
              AppSpacing.xxxl,
              AppSpacing.xxxl,
              AppSpacing.xxxl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PrimaryButton(label: 'Editar', onPressed: onEdit, expand: true),
                const SizedBox(height: AppSpacing.lg),
                _MetaRow(
                  label: metadataLabel,
                  value: _formatDate(metadataDate),
                  colors: colors,
                ),
                SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Formatea una fecha en español: «15 may 2026, 18:30».
  static String _formatDate(DateTime dt) {
    const months = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $h:$m';
  }
}

/// Fila de metadato alineada como en el detalle de citas.
class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.label,
    required this.value,
    required this.colors,
  });

  final String label;
  final String value;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTypography.bodySm.copyWith(color: colors.muted),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text('•', style: AppTypography.bodySm.copyWith(color: colors.muted)),
          const SizedBox(width: AppSpacing.sm),
          Text(
            value,
            style: AppTypography.bodySm.copyWith(color: colors.muted),
          ),
        ],
      ),
    );
  }
}
