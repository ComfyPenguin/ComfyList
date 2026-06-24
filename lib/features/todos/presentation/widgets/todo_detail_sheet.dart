import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/core/theme/app_spacing.dart';
import '../../../../shared/core/theme/app_theme.dart';
import '../../../../shared/core/theme/app_typography.dart';
import '../../domain/entities/todo.dart';
import '../providers/todos_provider.dart';
import '../providers/todos_state.dart';

/// Bottom sheet que muestra los detalles de una tarea (solo lectura).
///
/// Se presenta mediante `showModalBottomSheet` desde la lista de tareas.
/// Al pulsar «Editar» cierra el sheet y navega a la pantalla de edición
/// a través del callback [onEdit].
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

    return switch (state) {
      TodosInitial() || TodosLoading() => Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
          child: const Center(child: CircularProgressIndicator()),
        ),
      TodosError(:final failure) => Padding(
          padding: const EdgeInsets.all(AppSpacing.xxxl),
          child: Center(
            child: Text(
              failure.message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMd.copyWith(color: colors.body),
            ),
          ),
        ),
      TodosData(:final items) => _buildContent(context, items, colors),
    };
  }

  Widget _buildContent(
    BuildContext context,
    List<Todo> items,
    AppColors colors,
  ) {
    final todo = items.cast<Todo?>().firstWhere(
          (t) => t?.id == todoId,
          orElse: () => null,
        );

    // Si la tarea fue eliminada mientras el sheet estaba abierto.
    if (todo == null) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Center(
          child: Text(
            'Tarea no encontrada.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMd.copyWith(color: colors.body),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxxl,
        AppSpacing.sm,
        AppSpacing.xxxl,
        AppSpacing.xxxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera: título + botón editar.
          Row(
            children: [
              Expanded(
                child: Text(
                  'Detalles de la tarea',
                  style: AppTypography.displaySm.copyWith(color: colors.ink),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Editar',
                onPressed: onEdit,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // Badge de estado.
          _StatusBadge(isDone: todo.isDone, colors: colors),
          const SizedBox(height: AppSpacing.xl),

          // Título.
          Text(
            todo.title,
            style: AppTypography.displayMd.copyWith(
              color: colors.ink,
              decoration: todo.isDone ? TextDecoration.lineThrough : null,
            ),
          ),

          // Descripción.
          if (todo.description != null && todo.description!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Notas',
              style: AppTypography.bodySmStrong.copyWith(color: colors.muted),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              todo.description!,
              style: AppTypography.bodyMd.copyWith(color: colors.body),
            ),
          ],

          // Fechas.
          const SizedBox(height: AppSpacing.xxxl),
          _MetaRow(
            label: 'Creada',
            value: _formatDate(todo.createdAt),
            colors: colors,
          ),
          const SizedBox(height: AppSpacing.sm),
          _MetaRow(
            label: 'Actualizada',
            value: _formatDate(todo.updatedAt),
            colors: colors,
          ),
          const SizedBox(height: AppSpacing.xxxl),
          // Espacio inferior para seguridad del sheet.
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }

  /// Formatea una fecha en español: «15 may 2026, 18:30».
  static String _formatDate(DateTime dt) {
    const months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $h:$m';
  }
}

/// Badge pill que indica si la tarea está completada o pendiente.
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isDone, required this.colors});

  final bool isDone;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: isDone
            ? colors.success.withValues(alpha: 0.1)
            : colors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        isDone ? 'Completada' : 'Pendiente',
        style: AppTypography.bodySmStrong.copyWith(
          color: isDone ? colors.success : colors.warning,
        ),
      ),
    );
  }
}

/// Fila de metadato: etiqueta en muted + valor en body.
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
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: AppTypography.bodySm.copyWith(color: colors.muted),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTypography.bodySm.copyWith(color: colors.body),
          ),
        ),
      ],
    );
  }
}