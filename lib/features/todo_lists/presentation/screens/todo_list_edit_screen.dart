import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/core/theme/app_spacing.dart';
import '../../../../shared/core/theme/app_theme.dart';
import '../../../../shared/core/theme/app_typography.dart';
import '../../../../shared/ui/buttons/primary_button.dart';
import '../../../../shared/ui/dialogs/confirm_action_dialog.dart';
import '../../../../shared/ui/inputs/app_text_field.dart';
import '../../../../shared/ui/text/app_tag.dart';
import '../../domain/entities/todo_list.dart';
import '../../domain/entities/todo_list_icons.dart';
import '../providers/todo_lists_provider.dart';
import '../providers/todo_lists_state.dart';
import '../widgets/icon_picker.dart';

/// Radio de las cards del formulario — espejo de las tiles de la app.
const double _cardRadius = 32;

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

    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    final confirmed = await ConfirmActionDialog.show(
      context,
      title: '¿Eliminar lista?',
      message:
          '«$_hydratedName» y todas sus tareas se eliminarán permanentemente. '
          'Esta acción no se puede deshacer.',
      confirmLabel: 'Eliminar',
      destructive: true,
    );
    if (!confirmed) return;

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
              child: AppTag(label: 'Así quedará tu lista'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _ListPreview(iconKey: _iconKey, nameListenable: _nameCtrl),
          const SizedBox(height: AppSpacing.xxl),
          AppTextField(
            controller: _nameCtrl,
            label: 'Nombre',
            hint: 'Ej: Compra semanal',
            textInputAction: TextInputAction.done,
            errorText: _nameError,
            cardStyle: true,
          ),
          const SizedBox(height: AppSpacing.md),
          IconPicker(
            selectedKey: _iconKey,
            onChanged: (k) => setState(() => _iconKey = k),
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
              child: const Text('Eliminar lista'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Réplica de una fila de la pantalla de listas: muestra en vivo cómo quedará
/// la lista con el nombre y el icono elegidos.
class _ListPreview extends StatelessWidget {
  const _ListPreview({required this.iconKey, required this.nameListenable});

  final String iconKey;
  final ValueListenable<TextEditingValue> nameListenable;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = colors.canvas.computeLuminance() < 0.05;
    final borderColor = isDark
        ? colors.ink.withValues(alpha: 0.18)
        : colors.ink.withValues(alpha: 0.12);

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: nameListenable,
      builder: (context, value, _) {
        final name = value.text.trim();
        final isEmpty = name.isEmpty;

        return Container(
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            color: colors.canvas,
            borderRadius: BorderRadius.circular(_cardRadius),
            border: Border.all(color: borderColor, width: 1.2),
          ),
          child: Row(
            children: [
              Icon(
                TodoListIcons.resolve(iconKey),
                color: isEmpty ? colors.muted : colors.ink,
                size: 28,
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Text(
                  isEmpty ? 'Sin nombre' : name,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMdStrong.copyWith(
                    color: isEmpty ? colors.muted : colors.ink,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: colors.muted),
            ],
          ),
        );
      },
    );
  }
}
