import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/core/theme/app_spacing.dart';
import '../../../../shared/core/theme/app_theme.dart';
import '../../../../shared/core/theme/app_typography.dart';
import '../../../../shared/ui/buttons/primary_button.dart';
import '../../../../shared/ui/inputs/app_text_field.dart';
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

    final colors = context.colors;
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar tarea?'),
        content: Text(
          '«$_hydratedTitle» se eliminará permanentemente. Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: colors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Editar tarea' : 'Nueva tarea',
          style: AppTypography.displaySm.copyWith(color: colors.ink),
        ),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Eliminar',
              onPressed: _delete,
            ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xxxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                controller: _titleCtrl,
                label: 'Título',
                hint: '¿Qué tienes que hacer?',
                textInputAction: TextInputAction.next,
                errorText: _titleError,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _descCtrl,
                label: 'Notas (opcional)',
                maxLines: 4,
              ),
              const SizedBox(height: AppSpacing.xxxl),
              PrimaryButton(
                label: _isEditing ? 'Guardar' : 'Crear',
                onPressed: _submit,
                expand: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
