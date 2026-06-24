import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/core/theme/app_spacing.dart';
import '../../../../shared/core/theme/app_theme.dart';
import '../../../../shared/core/theme/app_typography.dart';
import '../../../../shared/ui/buttons/app_primary_button.dart';
import '../../../../shared/ui/inputs/app_text_field.dart';
import '../../domain/entities/todo_list.dart';
import '../../domain/entities/todo_list_icons.dart';
import '../providers/todo_lists_provider.dart';
import '../providers/todo_lists_state.dart';
import '../widgets/icon_picker.dart';

/// Pantalla unificada de creación y edición de listas. Si [id] es null →
/// crear; si no → editar (con opción de eliminar la lista y sus tareas).
class TodoListEditScreen extends ConsumerStatefulWidget {
  const TodoListEditScreen({super.key, this.id});

  final String? id;

  @override
  ConsumerState<TodoListEditScreen> createState() =>
      _TodoListEditScreenState();
}

class _TodoListEditScreenState extends ConsumerState<TodoListEditScreen> {
  final _nameCtrl = TextEditingController();
  String? _nameError;
  String _iconKey = TodoListIcons.defaultKey;
  bool _hydrated = false;
  String _hydratedName = '';

  bool get _isEditing => widget.id != null;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _hydrateFromState(TodoListsState s) {
    if (_hydrated || !_isEditing) return;
    if (s is TodoListsData) {
      final list =
          s.items.where((l) => l.id == widget.id).cast<TodoList?>().firstWhere(
                (e) => true,
                orElse: () => null,
              );
      if (list != null) {
        _nameCtrl.text = list.name;
        _iconKey = list.iconKey;
        _hydratedName = list.name;
        _hydrated = true;
      }
    }
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'El nombre no puede estar vacío.');
      return;
    }
    setState(() => _nameError = null);

    final notifier = ref.read(todoListsProvider.notifier);

    if (_isEditing) {
      await notifier.updateFields(
        id: widget.id!,
        name: name,
        iconKey: _iconKey,
      );
    } else {
      await notifier.create(name: name, iconKey: _iconKey);
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
        title: const Text('¿Eliminar lista?'),
        content: Text(
          '«$_hydratedName» y todas sus tareas se eliminarán permanentemente. '
          'Esta acción no se puede deshacer.',
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

    await ref.read(todoListsProvider.notifier).delete(widget.id!);
    if (!mounted) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('Lista «$_hydratedName» eliminada.')),
      );
    router.pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(todoListsProvider);
    final colors = context.colors;
    _hydrateFromState(state);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Editar lista' : 'Nueva lista',
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
                controller: _nameCtrl,
                label: 'Nombre',
                hint: 'Ej: Compra semanal',
                autofocus: !_isEditing,
                textInputAction: TextInputAction.done,
                errorText: _nameError,
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'Icono',
                style: AppTypography.bodyMdStrong.copyWith(color: colors.ink),
              ),
              const SizedBox(height: AppSpacing.md),
              IconPicker(
                selectedKey: _iconKey,
                onChanged: (k) => setState(() => _iconKey = k),
              ),
              const SizedBox(height: AppSpacing.xxxl),
              AppPrimaryButton(
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
