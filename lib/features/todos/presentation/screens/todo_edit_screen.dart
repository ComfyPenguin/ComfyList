import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/core/theme/app_radius.dart';
import '../../../../shared/core/theme/app_spacing.dart';
import '../../../../shared/core/theme/app_stroke.dart';
import '../../../../shared/core/theme/app_theme.dart';
import '../../../../shared/core/theme/app_typography.dart';
import '../../../../shared/ui/buttons/primary_button.dart';
import '../../../../shared/ui/dialogs/confirm_action_dialog.dart';
import '../../../../shared/ui/inputs/app_text_field.dart';
import '../../../../shared/ui/text/app_tag.dart';
import '../../domain/entities/todo.dart';
import '../providers/todos_provider.dart';
import '../providers/todos_state.dart';

/// Pantalla unificada de creación y edición de tareas para una lista
/// concreta. Si [id] es null → crear; si no → editar.
class TodoEditScreen extends ConsumerStatefulWidget {
  const TodoEditScreen({super.key, required this.listId, this.id});

  final String listId;
  final String? id;

  @override
  ConsumerState<TodoEditScreen> createState() => _TodoEditScreenState();
}

class _TodoEditScreenState extends ConsumerState<TodoEditScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String? _titleError;
  bool _hydrated = false;
  String _hydratedTitle = '';

  bool get _isEditing => widget.id != null;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _hydrateFromState(TodosState s) {
    if (_hydrated || !_isEditing) return;
    if (s is TodosData) {
      final todo =
          s.items.where((t) => t.id == widget.id).cast<Todo?>().firstWhere(
                (e) => true,
                orElse: () => null,
              );
      if (todo != null) {
        _titleCtrl.text = todo.title;
        _descCtrl.text = todo.description ?? '';
        _hydratedTitle = todo.title;
        _hydrated = true;
      }
    }
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      setState(() => _titleError = 'El título no puede estar vacío.');
      return;
    }
    setState(() => _titleError = null);

    final notifier = ref.read(todosProvider(widget.listId).notifier);
    final desc = _descCtrl.text.trim();

    if (_isEditing) {
      await notifier.updateFields(
        id: widget.id!,
        title: title,
        description: desc.isEmpty ? null : desc,
        clearDescription: desc.isEmpty,
      );
    } else {
      await notifier.create(
        title: title,
        description: desc.isEmpty ? null : desc,
      );
    }
    if (mounted) context.pop();
  }

  Future<void> _delete() async {
    if (!_isEditing) return;

    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    final confirmed = await ConfirmActionDialog.show(
      context,
      title: '¿Eliminar tarea?',
      message:
          '«$_hydratedTitle» se eliminará permanentemente. '
          'Esta acción no se puede deshacer.',
      confirmLabel: 'Eliminar',
      destructive: true,
    );
    if (!confirmed) return;

    await ref.read(todosProvider(widget.listId).notifier).delete(widget.id!);
    if (!mounted) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('Tarea «$_hydratedTitle» eliminada.')),
      );
    router.pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(todosProvider(widget.listId));
    final colors = context.colors;
    _hydrateFromState(state);

    // El TopBar del shell se superpone al contenido: reservamos su altura
    // (iconButton + padding del AppBar) más un margen hasta la primera card.
    final topOffset = MediaQuery.paddingOf(context).top + 56 + AppSpacing.md;

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          topOffset,
          AppSpacing.lg,
          AppSpacing.section,
        ),
        children: [
          // Mismo sangrado que las cabeceras de grupo de citas.
          const Padding(
            padding: EdgeInsets.only(left: AppSpacing.xl),
            child: Align(
              alignment: Alignment.centerLeft,
              child: AppTag(label: 'Así quedará tu tarea'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _TodoPreview(titleCtrl: _titleCtrl, descriptionCtrl: _descCtrl),
          const SizedBox(height: AppSpacing.xxl),
          AppTextField(
            controller: _titleCtrl,
            label: 'Título',
            hint: '¿Qué tienes que hacer?',
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            errorText: _titleError,
            cardStyle: true,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _descCtrl,
            label: 'Notas (opcional)',
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            cardStyle: true,
          ),
          const SizedBox(height: AppSpacing.xxxl),
          PrimaryButton(
            label: _isEditing ? 'Guardar' : 'Crear',
            onPressed: _submit,
            expand: true,
          ),
          if (_isEditing) ...[
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              onPressed: _delete,
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.error,
                minimumSize: const Size.fromHeight(52),
                side: BorderSide(
                  color: colors.error.withValues(alpha: 0.5),
                ),
              ),
              child: const Text('Eliminar tarea'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Réplica de una fila de la lista de tareas: muestra en vivo cómo quedará
/// la tarea con el título y las notas introducidos.
class _TodoPreview extends StatelessWidget {
  const _TodoPreview({required this.titleCtrl, required this.descriptionCtrl});

  final TextEditingController titleCtrl;
  final TextEditingController descriptionCtrl;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return ListenableBuilder(
      listenable: Listenable.merge([titleCtrl, descriptionCtrl]),
      builder: (context, _) {
        final title = titleCtrl.text.trim();
        final description = descriptionCtrl.text.trim();
        final isEmpty = title.isEmpty;

        return Container(
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            color: colors.canvas,
            borderRadius: AppRadius.brTile,
            border: Border.all(
              color: colors.cardBorder,
              width: AppStroke.hairline,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isEmpty ? 'Sin título' : title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMdStrong.copyWith(
                        color: isEmpty ? colors.muted : colors.ink,
                      ),
                    ),
                    if (description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Text(
                          description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySm.copyWith(
                            color: colors.muted,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
